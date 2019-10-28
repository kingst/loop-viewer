import base64
from datetime import datetime
from datetime import timedelta
import json
import logging
import os
import random
import time
import urllib2

import creds
from models import Session
from models import User

from api.error import BTError
import api.error as error
import api.phone as phone
#import api.apple_api as apple_api

from twilio.rest import TwilioRestClient
from twilio.rest.exceptions import TwilioRestException
from twilio.rest.lookups import TwilioLookupsClient

from google.appengine.ext import ndb

TWILIO_SID = creds.TWILIO_SID
TWILIO_AUTH_TOKEN = creds.TWILIO_AUTH_TOKEN
TWILIO_NUMBER = creds.TWILIO_NUMBER

TEST_NUMBERS = ['+15005551183', '+15005551000', '+15005551001']


# these functions aren't covered and they're mostly just stubs to make
# testing a bit easier

def _send_sms(phone_number, message):  # pragma: no cover
    client = TwilioRestClient(TWILIO_SID, TWILIO_AUTH_TOKEN)
    rv = client.messages.create(to=phone_number,
                                from_=TWILIO_NUMBER,
                                body=message)
    return {'status': rv.status,
            'error_code': rv.error_code,
            'error_message': rv.error_message}


def _utcnow():  # pragma: no cover
    return datetime.utcnow()


def _generate_short_code():  # pragma: no cover
    return str(int(os.urandom(4).encode('hex'), 16) % 1000000).zfill(6)


def _twilio_lookup(phone_number):  # pragma: no cover
    client = TwilioLookupsClient(TWILIO_SID, TWILIO_AUTH_TOKEN)
    number = client.phone_numbers.get(phone_number, include_carrier_info=True)

    return {'phone_number': number.phone_number,
            'carrier_type': number.carrier.get('type', 'landline')}


def lookup_number(phone_number):
    """ given a phone number, check if valid, convert to e164 and get
    Phone object """

    # XXX FIXME we should probably cache to avoid too many Twilio lookups

    try:
        number = _twilio_lookup(phone_number)
        carrier_type = number['carrier_type']

        phone_number = number['phone_number']
        if carrier_type == 'landline' and phone_number not in TEST_NUMBERS:
            raise BTError(error.CANT_SMS_LANDLINES)

    except TwilioRestException as tre:
        logging.exception(tre)
        if tre.status == 404:
            raise BTError(error.INVALID_PHONE_NUMBER)
        else:
            raise BTError(error.GENERAL_ERROR)

    # at this point we know we have a valid phone number and it's not
    # a landline. Also, this is formatted with E.164
    return phone.lookup_or_create(number['phone_number'])


def _send_path_rate_limits(phone_verification, current_time):

    # per phone rate limits. Note: this coveres both the number of
    # codes we'll send to a phone in a day as well as the number of
    # times we'll let someone check a code in a day
    if phone_verification.code_sent_at != current_time.date():
        phone_verification.code_sent_at = current_time.date()
        phone_verification.codes_sent = 0
        phone_verification.codes_checked = 0

    # we'll only send 10 codes per day for either type of verification
    # before they verify
    if phone_verification.codes_sent >= 10:
        raise BTError(error.CODES_SENT_RATE_LIMIT)


def _generate_verification_code(phone_data, current_time):
    phone_number = phone_data.e164_number()

    phone_verification = phone_data.short_code

    # set new pin codes for new entries or expired existing entries
    code_valid_until = phone_verification.code_valid_until
    if phone_verification.verification_code is None or \
            code_valid_until <= (current_time + timedelta(minutes=10)):

        # so apple can test
        if phone_number in TEST_NUMBERS:
            phone_verification.verification_code = '913218'  # pragma: no cover
        else:
            phone_verification.verification_code = _generate_short_code()

        phone_verification.code_valid_until = _utcnow() + timedelta(minutes=20)


def send_login_sms(phone_number):  # pragma: no cover
    return send_sms(phone_number, "Your Growth Metrics Wallet code is: {short_code}")


@ndb.transactional
def send_sms(phone_number, message=""):
    # XXX message has a default parameter for unit tests, we should
    # fix this at some point
    phone_data = lookup_number(phone_number)
    current_time = _utcnow()
    _send_path_rate_limits(phone_data.short_code, current_time)
    _generate_verification_code(phone_data, current_time)

    verification_code = phone_data.short_code.verification_code
    message = message.format(short_code=verification_code)

    rv = _send_sms(phone_data.e164_number(), message)

    if rv['status'] == 'failed':
        logging.error(rv['error_code'] + ' ' + rv['error_message'])
        raise BTError(error.GENERAL_ERROR)

    phone_data.short_code.codes_sent += 1
    phone_data.put()
    return {'e164_phone_number': phone_data.e164_number()}


def verify_short_code_login(phone_number, code):
    (new_user, user, auth_token) = _verify_code(phone_number, code)
    if user is None:
        raise BTError(error.INCORRECT_CODE)

    result = {'is_new_user': new_user,
              'user': user.to_dict(),
              'auth_token': auth_token}

    return result


def _reset_rate_limits(phone_verification):
    phone_verification.codes_checked = 0
    # if they enter a correct code we'll reset their daily limit
    # on the number of SMS sent to a phone as well
    phone_verification.codes_sent = 0
    # codes should only be used once
    phone_verification.code_valid_until = None
    phone_verification.verification_code = None


@ndb.transactional(xg=True)
def _verify_code(phone_number, code):
    phone_data = phone.lookup(phone_number)
    # it's a little strange that we use incorrect code if we test
    # a code for a user that doesn't exist, but whatever, clients
    # should never do this and it's probably a good way so that
    # people can't lookup who our users are
    if phone_data is None:
        raise BTError(error.INCORRECT_CODE)

    verification = phone_data.short_code

    # this is reset in the sending function because codes are only
    # good for 20 minutes
    if verification.codes_checked >= verification.max_failed_codes_per_day:
        raise BTError(error.CODE_VERIFY_RATE_LIMIT)

    if verification.code_valid_until is None or \
            verification.code_valid_until <= _utcnow():
        raise BTError(error.CODE_EXPIRED)

    if verification.verification_code != code:
        verification.codes_checked += 1
        phone_data.put()
        # it's important to return here so that we persist the model update
        return (None, None, None)

    # If we get here, the code is correct, cleanup the data
    _reset_rate_limits(phone_data.short_code)

    if phone_data.user is None:
        user = User()
        user.e164_phone_number = phone_number
        user.keyfile_password = base64.urlsafe_b64encode(os.urandom(24))
        phone_data.user = user.put()
        new_user = True
    else:
        new_user = False

    phone_data.put()

    auth_token = base64.urlsafe_b64encode(os.urandom(24))
    session = Session(id=auth_token)
    session.user = phone_data.user
    session.put()

    return (new_user, phone_data.user.get(), auth_token)

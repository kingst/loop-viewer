import datetime
import json
import logging
import os
import time
import urllib
import urllib2

import stripe

import api.sms_helper as sms_helper
import api.eth_helper as eth_helper
import api.decorators as decorators
import api.error as error
from api.error import BTError
from api.attempt_helper import increment_attempt
from models import Attempts, Strata, Promo, Lock
from apple_api import set_bits
import api.challenges as challenges

import creds
import apple_api

from google.appengine.api import memcache
from google.appengine.ext import ndb

# F0401:  9,0: Unable to import 'webapp2'
# pylint: disable=F0401
import webapp2

# stripe.api_key = creds.STRIPE_TEST

OUTBOUND_HTTP_TIMEOUT = 30


class SendVerificationCode(webapp2.RequestHandler):

    @decorators.api_call(['phone_number'], False)
    def post(self):
        # XXX FIXME need to add rate limiting per IP and phone number
        ip = self.request.remote_addr
        logging.info('verification request IP = ' + ip)

        phone_number = self.request.request_data['phone_number']
        return sms_helper.send_login_sms(phone_number)

class CheckChallenge(webapp2.RequestHandler):

    @decorators.api_call(['challenge_response'], False)
    def post(self):
        return challenges.check_card(self.request.args['challenge_response'])


class VerifyCode(webapp2.RequestHandler):

    @decorators.api_call(['e164_phone_number', 'code'], False)
    def post(self):

        logging.info(self.request.request_data['code'])

        self.request.request_data['attempt_type'] = 'login'
        if len(self.request.request_data['code']) != 6:
            if not increment_attempt(self.request):
                # block_user
                print("blocking user: {}".format(self.request.request_data['e164_phone_number']))

            raise BTError(error.INCORRECT_CODE)

        e164_phone_number = self.request.request_data['e164_phone_number']
        code = self.request.request_data['code']

        try:
            challenge_response = self.request.request_data.get('challenge_response',
                                                           None)
            build = self.request.request_data.get('build', '0000')
            return sms_helper.verify_short_code_login(e164_phone_number,
                                                      code,
                                                      challenge_response,
                                                      build)
        except BTError as e:
            if e.error_code == 'incorrect_code':
                if not increment_attempt(self.request):
                    # block_user
                    print("blocking user: {}".format(e164_phone_number))
            raise e


class EthAccount(webapp2.RequestHandler):

    @decorators.api_call([], True)
    def post(self, account_id):
        # get the account data from the blockchain
        result = eth_helper.get_account(account_id)
        result_data = {'account': result}

        # get the price from coinbases
        eth_usd = memcache.get(key='price:ETH-USD')
        if eth_usd is None:
            request = urllib2.Request('https://api.coinbase.com/v2/prices/ETH-USD/spot')
            response = urllib2.urlopen(request, timeout=OUTBOUND_HTTP_TIMEOUT)
            result = json.loads(response.read())
            eth_usd = result['data']['amount']

            memcache.add(key='price:ETH-USD', value=eth_usd, time=60)


        result_data['account']['ETH-USD'] = eth_usd

        return result_data


class EthPostTransaction(webapp2.RequestHandler):

    @decorators.api_call(['raw_tx'], True)
    def post(self):
        result = eth_helper.send_transaction(self.request.request_data['raw_tx'])
        return result


class CurrentUser(webapp2.RequestHandler):

    @decorators.api_call([], True)
    def post(self):
        if 'name' in self.request.request_data:
            self.request.user.name = self.request.request_data['name']

        if 'email' in self.request.request_data:
            self.request.user.email = self.request.request_data['email']

        self.request.user.put()

        return {'user': self.request.user.to_dict()}

    @decorators.api_call([], True)
    def get(self):
        return {'user': self.request.user.to_dict()}


def notify_sam(promo_code, account_id):
    message = 'Promo {0} redeemed, https://www.getgrowthmetrics.com/eth/to/{1}'.format(promo_code, account_id)
    if os.getenv('SERVER_SOFTWARE', '').startswith('Google App Engine/'):
        # Production
        sms_helper._send_sms('+12173726312', message)
    else:
        # Local development server
        logging.info(message)


class RedeemPromo(webapp2.RequestHandler):

    @decorators.api_call(['code', 'account_id'], True)
    def post(self):
        print(self.request.args['account_id'])
        code = self.request.args['code']
        if code == 'show_error':
            raise BTError(error.INCORRECT_CODE)
        elif code == 'test':
            for _ in range(10):
                @ndb.transactional
                def acquire():
                    lock = Lock.get_by_id('big_lock')
                    if lock is None:
                        lock = Lock(id='big_lock')
                    lock.owner = 'me'
                    lock.put()

                @ndb.transactional
                def release():
                    lock = Lock.get_by_id('big_lock')
                    lock.owner = None
                    lock.put()

                start_time = datetime.datetime.utcnow()          
                acquire()
                start_time_apple = datetime.datetime.utcnow()
                response = apple_api.get_bits(False,
                                              self.request.device['device_check_token'])
                response = apple_api.set_bits(False,
                                              self.request.device['device_check_token'],
                                              response['bit0'], response['bit1'])
                end_time_apple = datetime.datetime.utcnow()
                release()
                end_time = datetime.datetime.utcnow()
                s = 'Duration {0} apple {1} lock {2}'
                full_time = end_time - start_time
                apple_time = end_time_apple - start_time_apple
                lock_time = full_time - apple_time
                logging.info(s.format(full_time, apple_time, lock_time))
            raise BTError(error.PROMO_FAILED)

        promo = Promo.get_by_id(code)
        if not promo:
            raise BTError(error.PROMO_FAILED)

        user = self.request.user.to_dict()["e164_phone_number"]
        result = promo.redeem(user)
        if result == 0:
            # Check strata if promo can be redeemed
            self.request.request_data['attempt_type'] = 'promo'
            if not increment_attempt(self.request):
                # Restore promo consumed above
                promo.codes_left += 1
                promo.redeemed_users.remove(user)
                rsp = "device_redeemed"
            else:
                # invoke_promo_redemption()
                logging.info("Promotion redeemed successfully")
                rsp = "success"
        elif result == 1:
            rsp = "user_redeemed"
        elif result == 2 :
            rsp = "expired"
        else:
            rsp = "unknown"
        promo.put()

        if rsp != "success":
            if rsp == "device_redeemed":
                err = BTError(error.PROMO_FAILED)
                err.error_message = "All of these codes have been used"
            elif rsp == "user_redeemed":
                err = BTError(error.PROMO_FAILED)
                err.error_message = "You already redeemed this promo"
            elif rsp == "expired":
                err = BTError(error.PROMO_FAILED)
                err.error_message = "This promo is expired"
            else:
                err = BTError(error.PROMO_FAILED)
            raise err

        notify_sam(code, self.request.args['account_id'])
        return {'promo_response': rsp}


app = webapp2.WSGIApplication(
    [(r'/api/send_verification_code', SendVerificationCode),
     (r'/api/verify_code', VerifyCode),
     (r'/api/redeem_promo', RedeemPromo),
     (r'/api/check_challenge', CheckChallenge),
     (r'/api/user', CurrentUser),
     (r'/api/account/ETH/(.*)', EthAccount),
     (r'/api/tx/ETH', EthPostTransaction),
     ], debug=True)


def main():
    # E0602:158,4:main: Undefined variable 'run_wsgi_app'
    run_wsgi_app(app)  # pylint: disable=E0602


if __name__ == "__main__":
    main()

import base64
from datetime import datetime
from datetime import timedelta
import json
import logging
import os

from models import MaxAttempts, Attempts, Strata
from apple_api import get_bits, set_bits

from api.error import BTError

from google.appengine.ext import ndb

def increment_attempt(request):
    max_attempts = MaxAttempts.get_by_id('0')
    if max_attempts is None:
        max_attempts = MaxAttempts(id='0')
        max_attempts.put()

    if 'device_check_token' not in request.device:
        logging.error("device_check_token not found")
        return False
    if 'local_device_id' not in request.device:
        logging.error("local_device_id not found")
        return False

    device_check_token = request.device['device_check_token']
    local_device_id = request.device['local_device_id']
    is_debug = request.device.get('is_debug_build', 'no') == 'yes'

    attempts = Attempts.get_by_id(local_device_id)
    if attempts is None:
        attempts = Attempts(id=local_device_id)
        attempts.set_values()
        #check if hardware bits are unset
        hardware = get_bits(is_debug, device_check_token)
        if hardware is not None:
            # 00 is the only case we need to raise counter to be max of first Strata
            # other cases will result in auto leveling out
            if hardware['bit0'] == False and hardware['bit1'] == False:
                attempts.raise_to_max_of_first_strata()

    attempt_type = request.request_data["attempt_type"]

    response = get_bits(is_debug, device_check_token)
    bit0 = response['bit0']
    bit1 = response['bit1']
    hardware_strata = Strata(bit0=bit0, bit1=bit1)
    software_strata = attempts.software_strata

    if software_strata < hardware_strata:
        logging.info("Leveling out")
        attempts.level_out(hardware_strata)

    ## if hardware strata is less than software strata, we update the hardware strata to match the software one.
    elif software_strata > hardware_strata:
        logging.error("software strata is greater than hardware one")
        logging.info("setting hardware bits")
        set_bits(is_debug, device_check_token, software_strata.bit0, software_strata.bit1)

    try:
        software_strata = attempts.inc_attempt(attempt_type)
        if software_strata > hardware_strata:
            logging.info("setting hardware bits")
            set_bits(is_debug, device_check_token, software_strata.bit0, software_strata.bit1)
    except ValueError:
        attempts.put()
        return False

    attempts.put()
    return True

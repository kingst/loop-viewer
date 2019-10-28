import logging
import json


CANT_SMS_LANDLINES = {'code': 'cant_sms_landlines',
                      'message': "We can't send SMS to landlines"}
CANT_FIND_PHONE_NUMBER = {'code': 'cant_find_phone_number',
                          'message': ("We can't find your phone "
                                      "number in our system")}
CODE_EXPIRED = {'code': 'code_expired',
                'message': 'Your code expired'}
CODES_SENT_RATE_LIMIT = {'code': 'codes_sent_rate_limit',
                         'message': ('We can only send 5 codes '
                                     'per day to your number')}
CODE_VERIFY_RATE_LIMIT = {'code': 'code_verify_rate_limit',
                          'message': ('Too many verification attempts, '
                                      'try again tomorrow')}
GENERAL_ERROR = {'code': 'general_error',
                 'message': 'An unknown server error occurred'}
INCORRECT_CODE = {'code': 'incorrect_code',
                  'message': 'Incorrect verification code'}
INVALID_PHONE_NUMBER = {'code': 'invalid_phone_number',
                        'message': 'Your phone number is invalid'}
MISSING_ARGUMENT = {'code': 'missing_argument',
                    'message': 'The API call is missing a required argument'}
NOT_AUTHENTICATED = {'code': 'not_authenticated',
                     'message': 'You must be logged in to make this API call'}
NOT_AUTHORIZED = {'code': 'not_authorized',
                  'message': 'You are not authorized to make this API call'}
INVALID_TRANSFER = {'code': 'invalid_transfer',
                    'message': 'Your transfer ID is invalid'}
CHALLENGE_NEEDED = {'code': 'challenge_needed',
                    'message': 'You must pass a challenge'}
PROMO_FAILED = {'code': 'promo_failed',
                'message': 'We were unable to find this promo code'}

class BTError(Exception):
    """An error thrown by an API call """
    def __init__(self, error_dict):

        super(BTError, self).__init__()
        self.error_code = error_dict.get('code', None)
        self.error_message = error_dict.get('message', None)
        self.error_payload = None

        logging.warn(self.to_result())

    def to_result(self):
        """ Convert the error into a json string """
        return json.dumps({
            'status': 'error',
            'error_code': self.error_code,
            'error_message': self.error_message,
            'error_payload': self.error_payload
        }, indent=4)

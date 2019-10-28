import json
import jwt
import logging
import time
import urllib
import urllib2

import creds

import base64
import os

from jwt.contrib.algorithms.py_ecdsa import ECAlgorithm

jwt.register_algorithm('ES256', ECAlgorithm(ECAlgorithm.SHA256))

def jwt_token():
    f = open('AppleAuthKey.pem')
    secret = f.read()

    payload = {'iss': creds.APPLE_TEAM_ID, 'iat': long(time.time())}
    header = {'alg': 'ES256', 'kid': creds.APPLE_KEY_ID}
    token = jwt.encode(payload, secret, 'ES256', header)

    return token

def create_apple_payload(device_check_token, bit0=None, bit1=None):
    transaction_id = base64.urlsafe_b64encode(os.urandom(24))
    payload = {'device_token': device_check_token,
                'transaction_id': transaction_id,
                'timestamp': long(time.time()*1000)}

    if bit0 != None and bit1 != None:
        payload.update({'bit0': bit0,
                        'bit1': bit1,})
    elif bit0 != None and bit1 == None:
        payload.update({'bit0': bit0})
    elif bit0 == None and bit1 != None:
        payload.update({'bit1': bit1})

    payload = json.dumps(payload)
    return payload


def set_bits(is_debug, device_check_token, bit0, bit1):
    #if is_debug:
    #    url = 'https://api.development.devicecheck.apple.com'
    #else:
    #    url = 'https://api.devicecheck.apple.com'
    url = 'https://api.devicecheck.apple.com'

    jwttoken = jwt_token()
    headers = {'Authorization': 'Bearer {0}'.format(jwttoken)}
    payload = create_apple_payload(device_check_token, bit0, bit1)
    request = urllib2.Request(url + '/v1/update_two_bits',
                                payload,
                                headers)
    try:
        response = urllib2.urlopen(request, timeout=30)

    except urllib2.HTTPError as e:
        print("Exception!")
        print(e)
        print(e.reason)
        print(e.read())
        raise e

def get_bits(is_debug, device_check_token):
    #if is_debug:
    #    url = 'https://api.development.devicecheck.apple.com'
    #else:
    #    url = 'https://api.devicecheck.apple.com'
    url = 'https://api.devicecheck.apple.com'

    jwttoken = jwt_token()
    headers = {'Authorization': 'Bearer {0}'.format(jwttoken)}
    payload = create_apple_payload(device_check_token)
    request = urllib2.Request(url + '/v1/query_two_bits',
                                payload,
                                headers)
    try:
        response = urllib2.urlopen(request, timeout=30)
        response = str(response.read())

        if response == 'Failed to find bit state':
            set_bits(is_debug, device_check_token, False, False)
            #return get_bits(is_debug, device_check_token)
            return None

        return json.loads(response)

    except urllib2.HTTPError as e:
        print("Exception!")
        print(e)
        print(e.reason)
        print(e.read())
        raise e

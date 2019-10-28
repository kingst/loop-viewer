import base64
import datetime
import jinja2
import json
import operator
import os
import subprocess
import time
import urllib
import urllib2
import webapp2

from dateutil.parser import parse

import creds

URL = 'https://mainnet.infura.io/v3/025550191da74c958d43e5f1f171c9ee'

def json_rpc(method, params):
    headers = {'Content-Type': 'application/json'}

    data = {'jsonrpc': '2.0',
            'method': method,
            'params': params,
            'id': 1}

    post_data = json.dumps(data)

    username = creds.INFURA_PROJECT_ID
    password = creds.INFURA_PROJECT_SECRET
    basic_auth = base64.encodestring('%s:%s' % (username, password)).replace('\n', '')

    request = urllib2.Request(URL, post_data, headers)
    request.add_header("Authorization", "Basic {0}".format(basic_auth))
    response = urllib2.urlopen(request, timeout=25)
    result = response.read()
    
    return json.loads(result)


def get_transaction_by_hash(tx_hash):
    response = json_rpc('eth_getTransactionByHash', [tx_hash])
    return response['result']


def block_number():
    response = json_rpc('eth_blockNumber', [])
    return response['result']


def get_balance(account_id):
    response = json_rpc('eth_getBalance', [account_id, 'pending'])
    return response['result']


def get_transaction_count(account_id):
    response = json_rpc('eth_getTransactionCount', [account_id, 'pending'])
    return response['result']


def send_raw_transaction(raw_tx):
    response = json_rpc('eth_sendRawTransaction', [raw_tx])
    return response['result']


def send_transaction(raw_tx):
    tx_hash = send_raw_transaction(raw_tx)
    tx = get_transaction_by_hash(tx_hash)
    return {'tx_hash': tx_hash, 'tx': tx}

def get_account(account_id):
    balance = get_balance(account_id)
    tx_count = get_transaction_count(account_id)
    return {'balance': balance, 'transaction_count': tx_count}


#class GetTransaction(webapp2.RequestHandler):
#    def get(self, tx_hash):
#        tx = get_transaction_by_hash(tx_hash)
#        current_block_number = block_number()
#        self.response.write(json.dumps({'tx': tx, 'current_block_number': current_block_number}))
        


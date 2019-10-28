import base64
import json
import logging

import api.error as error
from api.error import BTError
#import api.apple_api as apple_api

from models import Session
from models import AnalyticsEvent

from google.appengine.ext import ndb


def api_call(required_args, auth_required=True):
    """Decorator for API calls.

    Parses JSON input, attaches an authenticated_user to the request,
    if needed, handles exeptions, and formats return values into JSON
    for callers.

    This decorator should be present on all API GET and POST requests.

    """
    def decorator_generator(function):

        def decoration(self, *args, **kwargs):
            event = AnalyticsEvent()
            event.path = self.request.path

            inner_decoration(self, *args, **kwargs)

            try:
                event.user = self.request.user.key
            except:
                pass
            
            # this is for the verify_code call where we try to get the
            # user even though it isn't an authenticated API call
            if event.user is None:
                try:
                    user_id = json.loads(self.response.body)['user']['user_id']
                    event.user = ndb.Key(urlsafe=user_id)
                except:
                    pass
            
            try:
                event.local_device_id = self.request.device['local_device_id']
            except:
                pass

            try:
                response = json.loads(self.response.body)
                event.result = response['status']
                if response['status'] == 'error' and response['error_code'] == 'challenge_needed':
                    event.challenge_type = response['error_payload']
            except:
                pass

            event.status = self.response.status_int
            event.put()


        def inner_decoration(self, *args, **kwargs):

            self.response.headers['Content-Type'] = 'application/json'
            # parse the arguments
            try:
                if self.request.method == 'GET':
                    request_data = {}
                    for key in self.request.GET.keys():
                        request_data[key] = self.request.GET[key]
                else:
                    request_data = json.loads(self.request.body)

                if 'x-authtoken' in self.request.headers:
                    request_auth_token = self.request.headers['x-authtoken']
                    request_data['auth_token'] = request_auth_token

                if 'x-build' in self.request.headers:
                    build = self.request.headers['x-build']
                    request_data['build'] = build
 
                if 'x-device' in self.request.headers:
                    device_encoded = self.request.headers['x-device']
                    logging.info('device header length = {0}'.format(len(device_encoded)))
                    device_string = base64.b64decode(device_encoded).decode('UTF-8')
                    self.request.device = json.loads(device_string)

                if auth_required:
                    required_args.append('auth_token')

                self.request.args = {}
                for arg_name in required_args:
                    self.request.args[arg_name] = request_data[arg_name]
                self.request.request_data = request_data
            except KeyError:
                bt_error = BTError(error.MISSING_ARGUMENT)
                self.response.write(bt_error.to_result())
                return

            if auth_required:
                auth_token = self.request.args['auth_token']
                session = Session.get_by_id(auth_token)
                if session is None:
                    bte = BTError(error.NOT_AUTHENTICATED)
                    self.response.write(bte.to_result())
                    return
                self.request.user = session.user.get()

            try:
                context = function(self, *args, **kwargs)
            except BTError as bte:
                self.response.write(bte.to_result())
                return
            except Exception as e:
                logging.exception(e)
                self.response.write(BTError(error.GENERAL_ERROR).to_result())
                return

            response = {}
            if context is None:
                context = {}
            for key in context.keys():
                response[key] = context[key]
            response['status'] = 'ok'

            self.response.write(json.dumps(response, indent=4))

        return decoration
    return decorator_generator

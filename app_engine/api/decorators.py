import base64
import json
import logging

import api.error as error
from api.error import BTError
#import api.apple_api as apple_api

from models import Session

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

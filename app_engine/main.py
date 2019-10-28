import json
import logging
import os
import webapp2

from models import DeviceStatus
from models import Treatment

from google.appengine.ext import ndb

import api.sms_helper as sms_helper
import api.decorators as decorators


def _create_uuid():
    uuid = os.urandom(24).encode('base64').replace("\n","")
    uuid = uuid.replace("/", "_").replace("+","-")

    return uuid


class ExperimentsTest(webapp2.RequestHandler):
    def get(self):
        print(self.request.headers)
        self.response.headers['Content-Type'] = 'application/json'
        self.response.out.write(json.dumps({'status': 'success'}))


class TreatmentHandler(webapp2.RequestHandler):
    def post(self):
        request_data = json.loads(self.request.body)
        print(self.request.headers)
        response = []
        bulk_put_list = []
        for treatment in request_data:
            uuid = _create_uuid()
            t = Treatment(id=uuid)
            t.raw_data = treatment
            bulk_put_list.append(t)
            response.append({'_id': uuid})

        #ndb.put_multi(bulk_put_list)
        logging.info(json.dumps(request_data, indent=4))
        self.response.headers['Content-Type'] = 'application/json'
        self.response.out.write(json.dumps(response))


class DeviceStatusHandler(webapp2.RequestHandler):
    def post(self):
        request_data = json.loads(self.request.body)
        print(self.request.headers)
        response = []
        for status in request_data:
            uuid = _create_uuid()
            d = DeviceStatus(id=uuid)
            d.raw_data = status
            #d.put()
            response.append({'_id': uuid})

        logging.info(json.dumps(request_data, indent=4))
        self.response.headers['Content-Type'] = 'application/json'
        self.response.out.write(json.dumps(response))

        
class SendVerificationCode(webapp2.RequestHandler):

    @decorators.api_call(['phone_number'], False)
    def post(self):
        # XXX FIXME need to add rate limiting per IP and phone number
        ip = self.request.remote_addr
        logging.info('verification request IP = ' + ip)

        phone_number = self.request.request_data['phone_number']
        return sms_helper.send_login_sms(phone_number)


class VerifyCode(webapp2.RequestHandler):

    @decorators.api_call(['e164_phone_number', 'code'], False)
    def post(self):
        e164_phone_number = self.request.request_data['e164_phone_number']
        code = self.request.request_data['code']
        return sms_helper.verify_short_code_login(e164_phone_number, code)


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

    
app = webapp2.WSGIApplication(
    [(r'/api/v1/experiments/test', ExperimentsTest),
     (r'/api/v1/treatments', TreatmentHandler),
     (r'/api/v1/devicestatus', DeviceStatusHandler),
     (r'/api/v1/send_verification_code', SendVerificationCode),
     (r'/api/v1/verify_code', VerifyCode),
     (r'/api/v1/user', CurrentUser)],
    debug=True)


def main():
    # E0602:158,4:main: Undefined variable 'run_wsgi_app'
    run_wsgi_app(app)  # pylint: disable=E0602


if __name__ == "__main__":
    main()

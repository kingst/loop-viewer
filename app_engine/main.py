import json
import logging
import os
import webapp2

from models import DeviceStatus
from models import Treatment

def _create_uuid():
    uuid = os.urandom(24).encode('base64').replace("\n","")
    uuid = uuid.replace("/", "_").replace("+","-")

    return uuid


class ExperimentsTest(webapp2.RequestHandler):
    def get(self):
        self.response.headers['Content-Type'] = 'application/json'
        self.response.out.write(json.dumps({'status': 'success'}))


class Treatments(webapp2.RequestHandler):
    def post(self):
        request_data = json.loads(self.request.body)
        
        response = []
        for treatment in request_data:
            uuid = _create_uuid()
            t = Treatment(id=uuid)
            t.raw_data = treatment
            t.put()
            response.append({'_id': uuid})

        logging.info(json.dumps(request_data, indent=4))
        self.response.headers['Content-Type'] = 'application/json'
        self.response.out.write(json.dumps(response))


class DeviceStatus(webapp2.RequestHandler):
    def post(self):
        request_data = json.loads(self.request.body)

        response = []
        for treatment in request_data:
            uuid = _create_uuid()
            t = Treatment(id=uuid)
            t.raw_data = treatment
            t.put()
            response.append({'_id': uuid})

        logging.info(json.dumps(request_data, indent=4))
        self.response.headers['Content-Type'] = 'application/json'
        self.response.out.write(json.dumps(response))


app = webapp2.WSGIApplication(
    [(r'/api/v1/experiments/test', ExperimentsTest),
     (r'/api/v1/treatments', Treatments),
     (r'/api/v1/devicestatus', DeviceStatus)],
    debug=True)


def main():
    # E0602:158,4:main: Undefined variable 'run_wsgi_app'
    run_wsgi_app(app)  # pylint: disable=E0602


if __name__ == "__main__":
    main()

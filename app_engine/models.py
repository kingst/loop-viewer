from google.appengine.ext import ndb


class Treatment(ndb.Model):
    ctime = ndb.DateTimeProperty(auto_now_add=True)
    raw_data = ndb.JsonProperty()


class DeviceStatus(ndb.Model):
    ctime = ndb.DateTimeProperty(auto_now_add=True)
    raw_data = ndb.JsonProperty()


class PhoneVerification(ndb.Model):
    """ Used to keep track of verification data and rate limits """
    verification_code = ndb.TextProperty()
    code_valid_until = ndb.DateTimeProperty()
    verified_at = ndb.DateTimeProperty()

    # we reset the codes_sent and codes_checked on successful verification
    codes_sent = ndb.IntegerProperty(default=0)
    code_sent_at = ndb.DateProperty()
    codes_checked = ndb.IntegerProperty(default=0)

    # these will be different for short and long codes
    max_failed_codes_per_day = ndb.IntegerProperty(default=5)



class Phone(ndb.Model):
    """ E.164 phone number is id """
    ctime = ndb.DateTimeProperty(auto_now_add=True)
    user = ndb.KeyProperty()
    short_code = ndb.LocalStructuredProperty(PhoneVerification,
                                             default=PhoneVerification())

    def e164_number(self):
        return self.key.id()


class User(ndb.Model):
    """ we use the app engine ID as the user ID """
    email = ndb.StringProperty()
    e164_phone_number = ndb.StringProperty()
    name = ndb.TextProperty()

    def user_id(self):
        return self.key.urlsafe()

    def to_dict(self):
        return {'email': self.email,
                'e164_phone_number': self.e164_phone_number,
                'name': self.name,
                'user_id': self.user_id()}


class Session(ndb.Model):
    """ Large random number is id """
    user = ndb.KeyProperty()
    ctime = ndb.DateProperty(auto_now_add=True)

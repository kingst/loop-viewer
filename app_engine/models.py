from google.appengine.ext import ndb


class Treatment(ndb.Model):
    ctime = ndb.DateTimeProperty(auto_now_add=True)
    raw_data = ndb.JsonProperty()


class DeviceStatus(ndb.Model):
    ctime = ndb.DateTimeProperty(auto_now_add=True)
    raw_data = ndb.JsonProperty()

import re

from api.error import BTError
import api.error as error
from models import Phone
from models import PhoneVerification


def lookup(number):
    return Phone.get_by_id(number)


def lookup_or_create(number):
    number = number.strip()
    phone = Phone.get_by_id(number)
    if phone is None:
        phone = Phone(id=number)
        phone.put()

    return phone

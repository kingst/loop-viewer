import logging
import os
import stripe

import creds

from api.error import BTError

def check_card(stripe_token):
    if os.getenv('SERVER_SOFTWARE', '').startswith('Google App Engine/'):
        # Production
        stripe.api_key = creds.STRIPE
    else:
        # Local development server
        stripe.api_key = creds.STRIPE_TEST

    try:
        charge = stripe.Charge.create(
            amount=100,
            currency="usd",
            description="Authorization for Growth Metrics",
            metadata={},
            capture=False,
            source=stripe_token
            )
    except stripe.error.CardError as e:
        # Since it's a decline, stripe.error.CardError will be caught
        charge = e.json_body

    if charge.get('status', 'error') != 'succeeded':
        err  = charge.get('error', {})
        message = err.get('message', 'Card error')
        raise BTError({'code': 'card_auth_failed', 'message': message})
    else:
        charge_id = charge['id']
        re = stripe.Refund.create(charge=charge_id)
        logging.info(re)

    return {}

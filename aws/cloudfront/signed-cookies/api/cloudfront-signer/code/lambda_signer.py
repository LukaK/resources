#!/bin/env python
import os
from datetime import datetime, timedelta

from .helpers import CloudfrontUtils, get_sm_secret

# global variables
CDN_DOMAIN_NAME = os.environ["CDN_DOMAIN_NAME"]
CDN_PRIVATE_PATH = os.environ["CDN_PRIVATE_PATH"]
REGION_NAME = os.environ["REGION_NAME"]
SECRET_NAME = os.environ["SM_PRIVATE_KEY_ID"]
PRIVATE_KEY_ID = os.environ["PRIVATE_KEY_ID"]

CF_UTILS = CloudfrontUtils(
    private_key_id=PRIVATE_KEY_ID,
    priv_key_value=get_sm_secret(secret_name=SECRET_NAME, region_name=REGION_NAME),
)


def lambda_handler(event: dict, context: object) -> dict:

    expire_at = datetime.now() + timedelta(minutes=5)
    signed_cookies = CF_UTILS.generate_signed_cookies(
        url=CDN_PRIVATE_PATH, expire_at=expire_at
    )

    return {
        "statusCode": 200,
        "multiValueHeaders": {
            "Set-Cookie": [
                f"{key}={value};Path=/;Secure;HttpOnly;Domain={CDN_DOMAIN_NAME}"
                for key, value in signed_cookies.items()
            ],
        },
    }

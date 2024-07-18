#!/bin/env python
import functools
import logging
from datetime import datetime

import boto3
import rsa
from botocore.exceptions import ClientError
from botocore.signers import CloudFrontSigner

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)


def get_sm_secret(secret_name: str, region_name: str) -> str:

    logger.info(f"Retrieving secrt: {secret_name}")

    session = boto3.session.Session()
    client = session.client(service_name="secretsmanager", region_name=region_name)

    try:
        get_secret_value_response = client.get_secret_value(SecretId=secret_name)
    except ClientError as e:
        raise e

    secret = get_secret_value_response["SecretString"]
    return secret


class CloudfrontUtils:

    def __init__(self, private_key_id: str, priv_key_value: str):
        logger.info("Initializing CloudfrontUtils")
        self._key_id = private_key_id
        self._priv_key = rsa.PrivateKey.load_pkcs1(priv_key_value.encode("utf8"))

        self._rsa_signer = functools.partial(
            rsa.sign, priv_key=self._priv_key, hash_method="SHA-1"
        )
        self._cf_signer = CloudFrontSigner(self._key_id, self._rsa_signer)

    def generate_signed_cookies(self, url: str, expire_at: datetime) -> dict[str, str]:

        logger.info("Generating signed cookies")
        policy = self._cf_signer.build_policy(url, expire_at).encode("utf8")
        policy_64 = self._cf_signer._url_b64encode(policy).decode("utf8")

        signature = self._rsa_signer(policy)
        signature_64 = self._cf_signer._url_b64encode(signature).decode("utf8")
        cookie_values = {
            "CloudFront-Policy": policy_64,
            "CloudFront-Signature": signature_64,
            "CloudFront-Key-Pair-Id": self._key_id,
        }

        logger.debug(f"Signed cookie values: {cookie_values}")
        return cookie_values

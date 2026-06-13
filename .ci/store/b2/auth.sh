#!/bin/sh -e

_set() {
    aws configure --profile b2 set "$1" "$2"
}

_set aws_access_key_id "$B2_KEY"
_set aws_secret_access_key "$B2_TOKEN"
_set output json
_set default.s3.signature_version s3v4

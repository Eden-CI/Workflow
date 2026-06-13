#!/bin/sh -e

aws --profile b2 --endpoint-url "https://$B2_URL" "$@"

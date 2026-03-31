#!/bin/sh -e

./b2.sh s3api list-buckets --query 'Buckets[].[Name]' --output text

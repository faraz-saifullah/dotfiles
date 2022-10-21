#!/bin/sh

if [ -z "HATICA_AWS_ACCESS_KEY_ID" ]
then
    echo "Missing HATICA_AWS_ACCESS_KEY_ID"
    exit 1
fi

if [ -z "HATICA_AWS_SECRET_ACCESS_KEY" ]
then
    echo "Missing HATICA_AWS_SECRET_ACCESS_KEY"
    exit 1
fi

if [ -z "$1" ]
then
    echo "Enter your aws mfa token"
    read token
else
    token=$1
fi

# Set default profile based on env variables
###########################################

aws configure set profile.user.aws_access_key_id $HATICA_AWS_ACCESS_KEY_ID
aws configure set profile.user.aws_secret_access_key $HATICA_AWS_SECRET_ACCESS_KEY

###########################################

creds=`aws --profile user sts get-session-token --serial-number ${AWS_MFA_DEVICE_ARN} --token-code ${token}`

access_key=`echo $creds | jq -r .Credentials.AccessKeyId`
secret_key=`echo $creds | jq -r .Credentials.SecretAccessKey`
session_token=`echo $creds | jq -r .Credentials.SessionToken`

# Set default profile based on generated mfa credentials
###########################################

aws configure set aws_access_key_id $access_key
aws configure set aws_secret_access_key $secret_key
aws configure set aws_session_token $session_token
aws configure set region us-east-1
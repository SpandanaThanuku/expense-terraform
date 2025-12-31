#!/bin/bash

yum install ansible python3.11-pip -y &>>/opt/userdata.log
pip3.11 install botocore boto3 &>>/opt/userdata.log

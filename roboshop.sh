#!/bin/bash
AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0c4d585bc760e07a7"
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")
ZONE_ID="Z0512139B2R70YUQAH76"
DOMAIN_NAME="lakshmireddy.site"

for instance in ${INSTANCES[@]}
do
    INSTANCE_ID=$(aws ec2 run-instances 
    --image-id ami-09c813fb71547fc4f
    --instance-type t2.micro          
    --security-groups sg-0c4d585bc760e07a7
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=test}]'
    --query Instances[0].Instance_Id' --output text
    if [ $instance != "frontend" ]
    then
          IP=aws ec2 describe-instances --instance-ids $INSTANCE_ID 
        --query 'Reservations[0].Instances[0].PublicIpAddress' \
        --output text)
        echo "$instance IP address is $IP"
    else
        IP=aws ec2 describe-instances --instance-ids $INSTANCE_ID 
        --query 'Reservations[0].Instances[0].PrivateIpAddress' \
        --output text)
    fi 
done
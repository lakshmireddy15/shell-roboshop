#!/bin/bash
AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0c4d585bc760e07a7"
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")
ZONE_ID="Z0512139B2R70YUQAH76"
DOMAIN_NAME="lakshmireddy.site"

for instance in ${INSTANCES[@]}
do
    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id $AMI_ID \
        --instance-type t2.micro \
        --security-group-ids $SG_ID \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
        --query 'Instances[0].InstanceId' \
        --output text)

    aws ec2 wait instance-running --instance-ids $INSTANCE_ID

    if [ $instance != "frontend" ]
    then
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
            --query 'Reservations[0].Instances[0].PrivateIpAddress' \
            --output text)
    else
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
            --query 'Reservations[0].Instances[0].PublicIpAddress' \
            --output text)
    fi 

    echo "$instance IP address is $IP"

    RECORD_NAME="$instance.$DOMAIN_NAME"

    aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '
    {
        "Comment": "Creating or Updating a record set for '$RECORD_NAME'",
        "Changes": [{
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "'$RECORD_NAME'",
                "Type": "A",
                "TTL": 1,
                "ResourceRecords": [{
                    "Value": "'$IP'"
                }]
            }
        }]
    }'
done

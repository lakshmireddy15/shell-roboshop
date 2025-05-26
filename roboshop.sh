#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0c4d585bc760e07a7"
INSTANCE_TYPE="t3.micro"
ZONE_ID="Z0512139B2R70YUQAH76"
DOMAIN_NAME="lakshmireddy.site"
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")

for instance in "${INSTANCES[@]}"; do
    echo "Launching instance: $instance"
    
    # Launch the EC2 instance
    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id "$AMI_ID" \
        --instance-type "$INSTANCE_TYPE" \
        --security-group-ids "$SG_ID" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
        --query "Instances[0].InstanceId" \
        --output text)
    
    echo "Launched $instance with Instance ID: $INSTANCE_ID"

    # Wait for the instance to be running
    echo "Waiting for $instance to enter running state..."
    aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

    # Get the IP address
    if [ "$instance" != "frontend" ]; then
        IP=$(aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --query "Reservations[0].Instances[0].PrivateIpAddress" \
            --output text)
        RECORD_NAME="$instance.$DOMAIN_NAME"
    else
        IP=$(aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --query "Reservations[0].Instances[0].PublicIpAddress" \
            --output text)
        RECORD_NAME="$DOMAIN_NAME"
    fi

    echo "$instance IP address: $IP"

    # Create DNS record in Route53
    echo "Creating/updating DNS record: $RECORD_NAME -> $IP"
    cat > /tmp/record.json <<EOF
{
  "Comment": "Creating record for $RECORD_NAME",
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "$RECORD_NAME",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{ "Value": "$IP" }]
    }
  }]
}
EOF

    aws route53 change-resource-record-sets \
        --hosted-zone-id "$ZONE_ID" \
        --change-batch file:///tmp/record.json

    echo "DNS record created for $RECORD_NAME"
    echo "----------------------------------------"
done

#!/bin/bash

SG_ID="sg-095a9a8243a52d49f" 
AMI_ID="ami-0220d79f3f480ecf5"
hosted_zone_id="ZZ01387941X390IQC8KQYJ"
domain_name="pavanreddy.online"


for instance in $@
do
    INSTANCE_ID=$( aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type "t3.micro" \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query 'Instances[0].InstanceId' \
    --output text )

    if [ $instance == "frontend" ]; then
        IP=$(
            aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query 'Reservations[].Instances[].PublicIpAddress' \
            --output text
        )
        record_name="$domain_name" # pavanreddy.online
       
    else
        IP=$(
            aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query 'Reservations[].Instances[].PrivateIpAddress' \
            --output text
        )
        record_name="$instance.$domain_name" #mongodb.pavanreddy.online
        
    fi

    echo "IP Address of $instance is $IP"

    aws route53 change-resource-record-sets \
    --hosted-zone-id $hosted_zone_id \
    --change-batch '
    {
        "Comment": "updating record",
        "Changes": [
            {
            "Action": "CREATE",
            "ResourceRecordSet": {
                "Name": "'$record_name'",
                "Type": "A",
                "TTL": 1,
                "ResourceRecords": [
               {
                "Value": "'$IP'"
                }
            ]
            }
         }
        ] 
    }'  
   

echo "Record $record_name updated with IP $IP"

done


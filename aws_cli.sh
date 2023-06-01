#!/bin/bash
# create-aws-vpc
#variables used in script:
availabilityZone="us-east-1a"
name="your VPC/network name"
vpcName="$name VPC"
subnetName="$name Subnet"
gatewayName="$name Gateway"
routeTableName="$name Route Table"
securityGroupName="$name Security Group"
vpcCidrBlock="10.0.0.0/16"
subNetCidrBlock="10.0.1.0/24"
port22CidrBlock="0.0.0.0/0"
destinationCidrBlock="0.0.0.0/0"
YOUR_AWS_ACCESS_KEY=YOUR_AWS_ACCESS_KEY
YOUR_AWS_SECRET_ACCESS_KEY=YOUR_AWS_SECRET_ACCESS_KEY
YOUR_PREFERRED_REGION=YOUR_PREFERRED_REGION

echo "Creating VPC..."

#install AWS CLI and kubectl and assign appropriate AWS credentials 
# Update the package lists for upgrades and new package installations
sudo apt-get update

#create vpc with cidr block /16
aws_response=$(aws ec2 create-vpc \
 --cidr-block "$vpcCidrBlock" \
 --output json)
vpcId=$(echo -e "$aws_response" |  /usr/bin/jq '.Vpc.VpcId' | tr -d '"')

#name the vpc
aws ec2 create-tags \
  --resources "$vpcId" \
  --tags Key=Name,Value="$vpcName"

#add dns support
modify_response=$(aws ec2 modify-vpc-attribute \
 --vpc-id "$vpcId" \
 --enable-dns-support "{\"Value\":true}")

#add dns hostnames
modify_response=$(aws ec2 modify-vpc-attribute \
  --vpc-id "$vpcId" \
  --enable-dns-hostnames "{\"Value\":true}")

#create internet gateway
gateway_response=$(aws ec2 create-internet-gateway \
 --output json)
gatewayId=$(echo -e "$gateway_response" |  /usr/bin/jq '.InternetGateway.InternetGatewayId' | tr -d '"')

#name the internet gateway
aws ec2 create-tags \
  --resources "$gatewayId" \
  --tags Key=Name,Value="$gatewayName"

#attach gateway to vpc
attach_response=$(aws ec2 attach-internet-gateway \
 --internet-gateway-id "$gatewayId"  \
 --vpc-id "$vpcId")

#create subnet for vpc with /24 cidr block
subnet_response=$(aws ec2 create-subnet \
 --cidr-block "$subNetCidrBlock" \
 --availability-zone "$availabilityZone" \
 --vpc-id "$vpcId" \
 --output json)
subnetId=$(echo -e "$subnet_response" |  /usr/bin/jq '.Subnet.SubnetId' | tr -d '"')

#name the subnet
aws ec2 create-tags \
  --resources "$subnetId" \
  --tags Key=Name,Value="$subnetName"

#enable public ip on subnet
modify_response=$(aws ec2 modify-subnet-attribute \
 --subnet-id "$subnetId" \
 --map-public-ip-on-launch)

#create security group
security_response=$(aws ec2 create-security-group \
 --group-name "$securityGroupName" \
 --description "Private: $securityGroupName" \
 --vpc-id "$vpcId" --output json)
groupId=$(echo -e "$security_response" |  /usr/bin/jq '.GroupId' | tr -d '"')

#name the security group
aws ec2 create-tags \
  --resources "$groupId" \
  --tags Key=Name,Value="$securityGroupName"

#enable port 22
security_response2=$(aws ec2 authorize-security-group-ingress \
 --group-id "$groupId" \
 --protocol tcp --port 22 \
 --cidr "$port22CidrBlock")

#create route table for vpc
route_table_response=$(aws ec2 create-route-table \
 --vpc-id "$vpcId" \
 --output json)
routeTableId=$(echo -e "$route_table_response" |  /usr/bin/jq '.RouteTable.RouteTableId' | tr -d '"')

#name the route table
aws ec2 create-tags \
  --resources "$routeTableId" \
  --tags Key=Name,Value="$routeTableName"

#add route for the internet gateway
route_response=$(aws ec2 create-route \
 --route-table-id "$routeTableId" \
 --destination-cidr-block "$destinationCidrBlock" \
 --gateway-id "$gatewayId")

#add route to subnet
associate_response=$(aws ec2 associate-route-table \
 --subnet-id "$subnetId" \
 --route-table-id "$routeTableId")

# Define your parameters
imageId=ami-0abcdef1234567890 # replace with a real image ID for your chosen OS
instanceType=t2.micro
keyName=my-key-pair
subnetId=subnet-1a2b3c4d # replace with a real subnet

###### and that you have an SSH key pair available for connecting to your instances.

# Launch the master node
masterInstanceId=$(aws ec2 run-instances --image-id $imageId --count 1 --instance-type $instanceType --key-name $keyName --security-group-ids $groupId --subnet-id $subnetId --query 'Instances[0].InstanceId' --output text)
echo "Launched master EC2 instance with ID: $masterInstanceId."

# Launch the worker nodes
for i in {1..2}
do
    workerInstanceId=$(aws ec2 run-instances --image-id $imageId --count 1 --instance-type $instanceType --key-name $keyName --security-group-ids $groupId --subnet-id $subnetId --query 'Instances[0].InstanceId' --output text)
    echo "Launched worker EC2 instance with ID: $workerInstanceId."

    # Assuming you have Docker, kubeadm, kubelet, and kubectl installed on these nodes, join them to the master node
    joinCommand=$(ssh -i $keyName.pem ubuntu@$masterIdAddress "sudo kubeadm token create --print-join-command")
    ssh -i $keyName.pem ubuntu@$masterIdAddress "$joinCommand"

######

echo " "
echo "VPC created:"
echo "Use subnet id $subnetId and security group id $groupId"
echo "To create your AWS instances"
# end of create-aws-vpc


# Define your parameters
# IMAGE_ID=ami-0abcdef1234567890 # replace with a real image ID for your chosen OS
# INSTANCE_TYPE=t2.micro
# KEY_NAME=my-key-pair
# SECURITY_GROUP_ID=sg-123abc45d # replace with a real security group
# SUBNET_ID=subnet-1a2b3c4d # replace with a real subnet



###### and that you have an SSH key pair available for connecting to your instances.



# # Launch the master node
# MASTER_INSTANCE_ID=$(aws ec2 run-instances --image-id $IMAGE_ID --count 1 --instance-type $INSTANCE_TYPE --key-name $KEY_NAME --security-group-ids $SECURITY_GROUP_ID --subnet-id $SUBNET_ID --query 'Instances[0].InstanceId' --output text)
# echo "Launched master EC2 instance with ID: $MASTER_INSTANCE_ID."

# # Launch the worker nodes
# for i in {1..2}
# do
#     WORKER_INSTANCE_ID=$(aws ec2 run-instances --image-id $IMAGE_ID --count 1 --instance-type $INSTANCE_TYPE --key-name $KEY_NAME --security-group-ids $SECURITY_GROUP_ID --subnet-id $SUBNET_ID --query 'Instances[0].InstanceId' --output text)
#     echo "Launched worker EC2 instance with ID: $WORKER_INSTANCE_ID."

#     # Assuming you have Docker, kubeadm, kubelet, and kubectl installed on these nodes, join them to the master node
#     JOIN_COMMAND=$(ssh -i $KEY_NAME.pem ubuntu@$MASTER_IP_ADDRESS "sudo kubeadm token create --print-join-command")
#     ssh -i $KEY_NAME.pem ubuntu@$WORKER_IP_ADDRESS "$JOIN_COMMAND"



# ######
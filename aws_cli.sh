#!/bin/bash
# create-aws-vpc
#variables used in script:

availabilityZone="us-east-1"
name="weclouddata"
vpcName="$name VPC"
subnetName="$name Subnet"
gatewayName="$name Gateway"
routeTableName="$name Route Table"
securityGroupName="$name Security Group"
vpcCidrBlock="10.0.0.0/16"
subNetCidrBlock="10.0.1.0/24"
port22CidrBlock="0.0.0.0/0"
destinationCidrBlock="0.0.0.0/0"

# YOUR_AWS_ACCESS_KEY=YOUR_AWS_ACCESS_KEY
# YOUR_AWS_SECRET_ACCESS_KEY=YOUR_AWS_SECRET_ACCESS_KEY
# YOUR_PREFERRED_REGION=YOUR_PREFERRED_REGION

softwareInstallData='#!/bin/bash
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y python3.10
curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo apt-get install -y openjdk-11-jdk
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh'

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
 --protocol tcp \
 --port 22 \
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

#add route table to subnet
associate_response=$(aws ec2 associate-route-table \
 --subnet-id "$subnetId" \
 --route-table-id "$routeTableId")

echo " "
echo "VPC created:"
echo "Use subnet id $subnetId and security group id $groupId"
echo "To create your AWS instances"

# Define your parameters 
imageId=$(aws ec2 describe-images --owners 099720109477 --filters 'Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*' 'Name=state,Values=available' --query 'reverse(sort_by(Images, &CreationDate))[:1].ImageId' --output text)
instanceType=t2.micro
keyName=$(aws ec2 create-key-pair --key-name weclouddatakeypair --query 'KeyMaterial' --output text > weclouddatakeypair.pem)
chmod 400 weclouddatakeypair.pem

# Launch the master node
masterInstanceId=$(aws ec2 run-instances \
  --image-id $imageId \
  --count 1 \
  --instance-type $instanceType \
  --key-name $keyName \
  --security-group-ids $groupId \
  --subnet-id $subnetId \
  --user-data "$softwareInstallData" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=worker-node-01}]' --query 'Instances[0].InstanceId' \
  --output text)

echo "Launched Master Node 1 EC2 instance with ID: $masterInstanceId."

# Launch the worker node 1
workerInstance1Id=$(aws ec2 run-instances \
  --image-id $imageId \
  --count 1 \
  --instance-type $instanceType \
  --key-name $keyName \
  --security-group-ids $groupId \
  --subnet-id $subnetId \
  --user-data "$softwareInstallData" \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "Launched Worker Node 1 EC2 instance with ID: $workerInstance1Id."

# Launch the worker node 2
workerInstance2Id=$(aws ec2 run-instances \
  --image-id $imageId \
  --count 1 \
  --instance-type $instanceType \
  --key-name $keyName \
  --security-group-ids $groupId \
  --subnet-id $subnetId \
  --user-data "$softwareInstallData" \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "Launched Worker Node 2 EC2 instance with ID: $workerInstance2Id."

# end of create-aws-vpc

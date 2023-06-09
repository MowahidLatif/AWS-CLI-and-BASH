Public repo link: https://github.com/MowahidLatif/AWS-CLI-and-BASH/tree/main

## Preparation

- Install awscli
`sudo apt install unzip`
`curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"`
`unzip awscliv2.zip`
`sudo ./aws/install`

- Add AWS Credentials with 'us-east-1' and 'json'
`aws configure`

Create bash shell script(s) that leverage the AWS CLI tool to create the following cloud architecture and set up:

## Resources in us-east-1

- VPC
- Internet gateway
- Internet gateway attached to VPC
- Public subnet
- Enable auto-assign public IP on public subnet
- Public route table for public subnet
- Route table has a routing rule to the internet gateway
- Associate the public subnet with the public route table

## EC2 instances

### Master node 1

- Size: t2.small
- Image: Ubuntu 20.04
- Installed software:
  - Python 3.10
  - Node 18.0
  - Java 11.0
  - Docker engine
- Tag:
  - key=Name, value=master-node-01

### Worker node 1

- Size: t2.micro
- Image: Ubuntu 20.04
- Installed software:
  - Python 3.10
  - Node 18.0
  - Java 11.0
  - Docker engine
- Tag:
  - key=Name, value=worker-node-01

### Worker node 2

- Size: t2.micro
- Image: Ubuntu 20.04
- Installed software:
  - Python 3.10
  - Node 18.0
  - Java 11.0
  - Docker engine
- Tag:
  - key=Name, value=worker-node-02

All three EC2 instances:

- Are in the same public subnet and VPC
- Are reachable to each other (e.g., via the ping command)
- Are accessible remotely by SSH
- All resources created are tagged:
  - key=project, value=wecloud

## Additional Information

- The scripts are stored in a public GitHub repo.
- Architectural diagram depicting the AWS cloud infrastructure setup.
- A README.md file in the GitHub repo containing:
  - URL to public GitHub repo
  - Instructions on how to run the scripts and deploy the cloud infrastructure
  - Pertinent diagrams

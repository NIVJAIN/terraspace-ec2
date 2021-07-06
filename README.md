
# Terraspace Project

This is a Terraspace project. It contains code to provision Cloud infrastructure built with [Terraform](https://www.terraform.io/) and the [Terraspace Framework](https://terraspace.cloud/).

## Deploy

To deploy all the infrastructure stacks:

    terraspace all up

To deploy individual stacks:

    terraspace up demo # where demo is app/stacks/demo

## Terrafile

To use more modules, add them to the [Terrafile](https://terraspace.cloud/docs/terrafile/).




## Installation
```
brew update
brew install awscli
aws configure  [enter your access keys]
Here are some useful commands to test that the AWS CLI is working:
aws s3 ls 

brew install terraform
brew tap boltops-tools/software
brew install terraspace
terraspace check_setup

terraspace new project terraspace-ec2 --plugin aws
cd terraspace-ec2
terraspace new module 1-ec2
terraspace new module 2-sg
terraspace new module 3-alb
terraspace new module 4-route53
terraspace new stack 1-launch-ec2

terraspace up 1-launch-ec2
terraspace up 1-launch-ec2 -y   # to deploy
terraspace down 1-launch-ec2 -y # to destroy

bucket name can be found here
/Users/blockchain/TAMATAR/TERRASPACE/terraspace-ec2/.terraspace-cache/ap-southeast-1/dev/stacks/1-launch-ec2
```
# Description
Use the Terraform Infrastructure as Code (or IaC) in this directory for deploying livetranslator on a cloud environment.

One Cloud deployment option is supported at this moment:

- Amazon Webservices Elastic Container Service (AWS ECS)

## Prerequisites
- AWS deployment account
- AWS access including Admin permissions for AWS IAM, ECS, EC2, VPC etc.
- Local installation of [Hashicorp Terraform](https://developer.hashicorp.com/terraform)
- AWS S3 access for shared terraform backend (optional)

## Terraform Installation
In short, for Debian/Ubuntu:

```
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y terraform
```

For details and/or other operating systems, follow instructions on https://developer.hashicorp.com/terraform/install.

## Terraform Initialization
Configure the AWS CLI with an account that has sufficient permissions, or sign in to AWS to obtain access credentials.

Set the desired AWS region and configure the AWS profile name:
```
export AWS_DEFAULT_REGION="eu-south-2"
export AWS_PROFILE="bcm_test"
```

Store the AWS credentials in `$HOME/.aws/credentials`, for example:

```
[bcm_test]
aws_access_key_id=ASIA................
aws_secret_access_key=<..........................................>
aws_session_token=
```

When checking out the infrastructure code for the first time, the terraform backend must be initialized, with the `terraform init` command:

```
Initializing the backend...

Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.99.1...
- Installed hashicorp/aws v5.99.1 (signed by HashiCorp)

Terraform has been successfully initialized!
```

*(Optional)* select the correct Terraform workspace. If there are multiple environments, the workspace corresponding to the AWS credential set should be selected:

```
terraform workspace list
* default
  test
```

Then select an environment: `terraform workspace select test`

Finally, ask terraform to plan a deployment. This will compare the current state with the desired state (as described in the terraform code), and produce an plan of execution:

`terraform plan`

# Troubleshooting

> Terraform initialization is failing with `Error: validating provider credentials: retrieving caller identity from STS: operation error STS: GetCallerIdentity`

This happens when the AWS credentials are invalid or have expired. Obtain new credentials and retry.

> Terraform plan fails on IAM operations, e.g.: `Error: reading IAM Role (livetranslator_ECS_TaskIAMRole_test): operation error IAM: GetRole, https response error StatusCode: 403`

Your AWS profile probably has insufficient permissions. For terraform, administrator privileges are required.
########################################################################################################################
## This resource returns a list of all AZ available in the region configured in the AWS credentials
########################################################################################################################

data "aws_availability_zones" "available" {}

########################################################################################################################
## Public Subnets (one public subnet per AZ)
########################################################################################################################

data "aws_subnets" "public" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name = "map-public-ip-on-launch"
    values  = ["true"]
  }
}

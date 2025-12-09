#creating peering connection between default and dev VPC using data sources for default vpc
data "aws_vpc" "default" {
  default = true
}
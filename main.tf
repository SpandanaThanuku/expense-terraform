module "vpc" {
  source = "./modules/vpc"
  for_each = var.vpc
  vpc_cidr = each.value["vpc_cidr"]
}
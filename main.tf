module "vpc" {
  source        = "./modules/vpc"
  for_each            = var.vpc
  vpc_cidr            = lookup(each.value, "vpc_cidr", null)
  public_subnets_cidr = lookup(each.value, "public_subnets_cidr", null)
  web_subnets_cidr    = lookup(each.value, "web_subnets_cidr", null)
  app_subnets_cidr    = lookup(each.value, "app_subnets_cidr", null)
  db_subnets_cidr     = lookup(each.value, "db_subnets_cidr", null)
  az                  = lookup(each.value, "az", null)

  env           = var.env
  project_name  = var.project_name
}


module "rds" {
  source = "./modules/rds"

  for_each            = var.rds
  allocated_storage   = lookup(each.value, "allocated_storage", null)
  db_name             = lookup(each.value, "db_name", null)
  engine              = lookup(each.value, "engine", null)
  engine_version      = lookup(each.value, "engine_version", null)
  instance_class      = lookup(each.value, "instance_class", null)
  family              = lookup(each.value, "family", null)

  env           = var.env
  project_name  = var.project_name
  kms_key_id    = var.kms_key_id

  subnet_ids     = lookup(lookup(module.vpc, "main", null), "app_subnets_ids", null)
  vpc_id         = lookup(lookup(module.vpc, "main", null), "vpc_id", null)
  sg_cidr_blocks = lookup(lookup(var.vpc, "main", null), "app_subnets_cidr", null)
}

module "backend" {
  depends_on = [module.rds]
  source     = "./modules/app"

  app_port            = var.backend_app_port
  bastion_cidrs       = var.bastion_cidrs
  component           = "backend"
  instance_capacity   = var.backend_instance_capacity
  instance_type       = var.backend_instance_type

  env                 = var.env
  project_name        = var.project_name

  sg_cidr_blocks      = lookup(lookup(var.vpc, "main", null), "app_subnets_cidr", null)
  vpc_id              = lookup(lookup(module.vpc, "main", null), "vpc_id", null)
  vpc_zone_identifier = lookup(lookup(module.vpc, "main", null), "app_subnets_ids", null)
  parameters          = ["arn:aws:ssm:us-east-1:348220191398:parameter/${var.env}.${var.project_name}.rds.*"]
  kms                 = var.kms_key_id
}

module "frontend" {
  source = "./modules/app"

  app_port            = var.frontend_app_port
  bastion_cidrs       = var.bastion_cidrs
  component           = "frontend"
  env                 = var.env
  instance_capacity   = var.frontend_instance_capacity
  instance_type       = var.frontend_instance_type
  project_name        = var.project_name
  sg_cidr_blocks      = lookup(lookup(var.vpc, "main", null), "public_subnets_cidr", null)
  vpc_id              = lookup(lookup(module.vpc, "main", null), "vpc_id", null)
  vpc_zone_identifier = lookup(lookup(module.vpc, "main", null), "web_subnets_ids", null)
  parameters          = []
  kms                 = var.kms_key_id

}

module "public-alb" {
  source = "./modules/alb"

  alb_name        = "public"
  env             = var.env
  project_name    = var.project_name
  acm_arn         = var.acm_arn
  internal        = false
  dns_name        = "frontend"
  zone_id         = var.zone_id

  sg_cidr_blocks  = ["0.0.0.0/0"]
  subnets         = lookup(lookup(module.vpc, "main", null), "public_subnets_ids", null)
  vpc_id          = lookup(lookup(module.vpc, "main", null), "vpc_id", null)
  target_group_arn = module.frontend.target_group_arn
  #target_group_arn = module.frontend.target_groups["target_group_name"].arn
}

module "private-alb" {
  source = "./modules/alb"

  alb_name        = "private"
  env             = var.env
  internal        = true
  project_name    = var.project_name
  dns_name        = "backend"
  acm_arn         = var.acm_arn
  zone_id         = var.zone_id
  sg_cidr_blocks  = lookup(lookup(var.vpc, "main", null), "web_subnets_cidr", null)
  subnets         = lookup(lookup(module.vpc, "main", null), "app_subnets_ids", null)
  vpc_id          = lookup(lookup(module.vpc, "main", null), "vpc_id", null)
  target_group_arn = module.backend.target_group_arn
}

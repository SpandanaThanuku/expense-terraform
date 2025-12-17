variable "env" {}
variable "project_name" {}
variable "kms_key_id" {}
variable "bastion_cidrs" {}

variable "vpc" {}
variable "rds" {}

variable "backend_app_port" {}
variable "backend_instance_capacity" {}
variable "backend_instance_type" {}

variable "frontend_app_port" {}
variable "frontend_instance_capacity" {}
variable "frontend_instance_type" {}

module "vpc" {
  source = "./modules/vpc"

  name                = var.project_name
  vpc_cidr            = var.vpc_cidr
  availability_zones   = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  nat_gateway_per_az  = var.nat_gateway_per_az
  tags                = local.common_tags
}

module "security" {
  source = "./modules/security"

  name              = var.project_name
  allowed_alb_cidrs = var.allowed_alb_cidrs
  vpc_id            = module.vpc.vpc_id
  tags              = local.common_tags
}

module "web" {
  source = "./modules/web"

  name                 = var.project_name
  vpc_id               = module.vpc.vpc_id
  public_subnet_ids    = module.vpc.public_subnet_ids
  private_subnet_ids   = module.vpc.private_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id
  web_security_group_id = module.security.web_security_group_id
  instance_type         = var.instance_type
  desired_capacity      = var.desired_capacity
  min_size              = var.min_size
  max_size              = var.max_size
  acm_certificate_arn   = var.acm_certificate_arn
  tags                  = local.common_tags
}

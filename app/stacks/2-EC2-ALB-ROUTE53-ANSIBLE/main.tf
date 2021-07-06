# This is where you put your resource declaration

# ------------------------------------------------------------------------------
# RETRIEVE EXISTING DOMAIN INFO.
# ------------------------------------------------------------------------------
data "aws_route53_zone" "ecs_domain" {
  name         = local.domain_name
  private_zone = false
}

data "aws_acm_certificate" "ecs_domain_certificate" {
  domain      = "*.${local.domain_name}"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

# ------------------------------------------------------------------------------
# VARIABLES
# ------------------------------------------------------------------------------

locals {
  project_name       = "TERRASPACE-TEST-JAIN"
  region             = "ap-southeast-1"
  init_tpl_file_name = "init.tpl"
  #   ami_id           = "ami-0d058fe428540cd89" #ububtu
  ami_id                   = "ami-0fab0953c3bb514a9" #amazon linux2
  public_subnet_id         = "subnet-08b1ad0d7506dca3f"
  private_subnet_id        = "subnet-08b1ad0d7506dca3f"
  instance_type            = "t2.small"
  root_volume_size         = "80"
  ansible_playbook = "${path.module}/../ansible/nginx.yaml"
  pem_file_name_wo_dot_pem = "RecommedationEngineeKP"
  vpc_id                   = "vpc-028b7724ac0331752"
  jump_host_security_group = ["sg-021bf7f871be99f3e", "sg-05057e074f565c0fa", "sg-0cc362e87c48e58ce"]
  lambda_rre_sg_id         = ["sg-061b81a6a74a4c682"]
  client_laptops_ip        = ["116.86.133.133/32"]
  jump_hosts_ip            = ["10.196.250.8/32", "116.86.133.133/32"]
  availability_zones       = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
  domain_name              = "aipo-imda.net"
  domain_host_name         = "rabbitmq"
  public_subnets = ["subnet-08b1ad0d7506dca3f", "subnet-0e13dde65836782b9"]
  security_group_map = {
    "description 0" = {
      port            = 80,
      cidr_blocks     = null,
      security_groups = local.jump_host_security_group,
      protocol        = "tcp"
    }
    "description 1" = {
      port            = 8080,
      cidr_blocks     = local.jump_hosts_ip,
      security_groups = local.jump_host_security_group,
      protocol        = "tcp"
    }
    "description 2" = {
      port            = 22,
      cidr_blocks     = local.jump_hosts_ip,
      security_groups = local.jump_host_security_group,
      protocol        = "tcp"
    }
    "description 3" = {
      port            = 5009,
      cidr_blocks     = null,
      security_groups = local.lambda_rre_sg_id,
      protocol        = "tcp"
    }
  }
   security_group_map_alb = {
    "description 0" = {
      port            = 80,
      cidr_blocks     = ["0.0.0.0/0"],
      security_groups = null,
      protocol        = "tcp"
    }
    "description 1" = {
      port            = 443,
      cidr_blocks     = ["0.0.0.0/0"],
      security_groups = null,
      protocol        = "tcp"
    }
  }
  default_tags = {
    Environment    = "Dev"
    Owner          = "Siyang"
    Project        = "RRE-STAGING"
    Requestor      = "Siyang"
    Creator        = "CloudTFEngineer-JAIN"
    Terraform      = "True"
    Scheduled      = "True"
    Schedule       = "True"
    TerraformState = "s3://terraform-jain-gcc/RRE/SIYANG-RRE-1.tfstate"
  }
  health_check = {
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
    interval            = 10
    path                = "/"
  }
  hosts2 = {
    "nginx" = {
      "tgport"  = "8080"
      "tgproto" = "HTTP"
    },
    # "rabbit" = {
    #   "tgport"  = "15672"
    #   "tgproto" = "HTTP"
    # }
    # ,
    # "nodeapp" = {
    #   "tgport"  = "3000"
    #   "tgproto" = "HTTP"
    # },
    # "service" = {
    #   "tgport"  = "5000"
    #   "tgproto" = "HTTP"
    # }
  }
}

# ------------------------------------------------------------------------------
# ALB SECURITY GROUP
# ------------------------------------------------------------------------------
module "alb_security_group" {
  source                   = "../../modules/2-sg"
  project_name             = local.project_name
  resource_type            = "ALB"
  region                   = local.region
  vpc_id                   = local.vpc_id
  default_tags             = local.default_tags
  jump_host_security_group = local.jump_host_security_group
  client_laptops_ip        = local.client_laptops_ip
  jump_hosts_ip            = local.jump_hosts_ip
  security_group_map       = local.security_group_map_alb
}

# ------------------------------------------------------------------------------
# EC2 SECURITY GROUP
# ------------------------------------------------------------------------------
module "security_groups" {
  # depends_on = [module.alb_security_group]
  source                   = "../../modules/2-sg"
  project_name             = local.project_name
  resource_type            = "EC2"
  region                   = local.region
  vpc_id                   = local.vpc_id
  default_tags             = local.default_tags
  jump_host_security_group = local.jump_host_security_group
  client_laptops_ip        = local.client_laptops_ip
  jump_hosts_ip            = local.jump_hosts_ip
  # security_group_map       = local.security_group_map
  security_group_map  = merge(local.security_group_map,{ "description 4" = {
      port            = 8080,
      cidr_blocks     = null,
      security_groups = [module.alb_security_group.sg_id],
      protocol        = "tcp"
    }} )
}

# ------------------------------------------------------------------------------
# EC2 WEBSERVER
# ------------------------------------------------------------------------------
module "ec2_webserver" {
  depends_on               = [module.security_groups]
  source                   = "../../modules/1-ec2"
  project_name             = local.project_name
  init_tpl_file_name       = local.init_tpl_file_name
  sec_grp_id               = module.security_groups.sg_id
  region                   = local.region
  vpc_id                   = local.vpc_id
  ami_id                   = local.ami_id
  subnet_id                = local.public_subnet_id
  instance_type            = local.instance_type
  pem_file_name_wo_dot_pem = local.pem_file_name_wo_dot_pem
  # ssh_username             = local.ssh_username
  # key_name                 = local.key_name
  # private_key_path         = local.private_key_path
  root_volume_size = local.root_volume_size
  # instance_name            = local.instance_name
  default_tags = local.default_tags
  # public_subnets           = local.public_subnets
  jump_host_security_group = local.jump_host_security_group
  client_laptops_ip        = local.client_laptops_ip
  jump_hosts_ip            = local.jump_hosts_ip
  # domain_name              = local.domain_name
  # domain_host_name         = local.domain_host_name
  # availability_zones = local.availability_zones

}

output "ec2_public_ip" {
  value = module.ec2_webserver.ec2_public_ip
}

output "aws_ec2_instance_id" {
  value = module.ec2_webserver.aws_ec2_instance_id
}


# ------------------------------------------------------------------------------
# ALB APPLICATION LOAD BALANCER
# ------------------------------------------------------------------------------
module "alb_ec2" {
  source = "../../modules/3-alb"
  depends_on = [module.alb_security_group, module.ec2_webserver]
  project_name = local.project_name
  public_subnets = local.public_subnets
  alb_security_group = [module.alb_security_group.sg_id]
  default_tags = local.default_tags
  hosts2 = local.hosts2
  domain_certificate_arn = data.aws_acm_certificate.ecs_domain_certificate.arn
  domain_name = local.domain_name
  aws_ec2_instance_id = module.ec2_webserver.aws_ec2_instance_id
}
# # ------------------------------------------------------------------------------
# # ROUTE53 DOMAIN UPDATES
# # ------------------------------------------------------------------------------
module "route53_domain" {
  depends_on = [module.alb_ec2]
  source = "../../modules/4-route53"
  domain_name = local.domain_name
  hosts2 = local.hosts2
  zone_id = data.aws_route53_zone.ecs_domain.zone_id
  aws_alb_dnsname = module.alb_ec2.aws_alb_dnsname
  aws_alb_zoneid = module.alb_ec2.aws_alb_zoneid
}


resource "null_resource" "test_box" {
  depends_on = [module.ec2_webserver]
  provisioner "local-exec" {
    # command = "ansible-playbook  -i ${module.ec2.aws_instance.nginx.public_ip}, --private-key ${local.private_key_path} nginx_ansible.yaml"
    # command = "ansible-playbook  -i ${module.s3.nginx_ip}, --private-key ${local.private_key_path} nginx.yaml"
    # command = "ansible-playbook  -i ${module.s3.nginx_ip}, --private-key vamakp.pem nginx.yaml"
    # command = "ansible-playbook  -i localhost, --private-key vamakp.pem ../ansible/nginx.yaml" 
    #  command = "ansible-playbook  -i localhost ../ansible/nginx.yaml"
    command = "ansible-playbook  -i ${module.ec2_webserver.ec2_public_ip}, --private-key RecommedationEngineeKP.pem ${local.ansible_playbook}"
    # command = "ansible-playbook  -i localhost ${local.ansible_playbook}"
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Create sh files for ec2 ssh login and running playbook during development work"
      echo ssh -i RecommedationEngineeKP.pem ec2-user@${module.ec2_webserver.ec2_public_ip} > amazonlinux2.sh
      echo ansible-playbook -i ${module.ec2_webserver.ec2_public_ip}, --user ec2-user --private-key RecommedationEngineeKP.pem ansible_playbook > run_playbook.sh
    EOT
  }
}
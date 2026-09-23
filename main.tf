module "vpc" {
  source = "./modules/vpc"

  name = "${var.ENV}-vpc"
  cidr = var.VPC["CIDR"]

  azs = ["${var.REGION}a", "${var.REGION}b"]
  private_subnets = var.VPC["SUBNET_PRIVATE"]
  public_subnets  = var.VPC["SUBNET_PUBLIC"]
  # database_subnets  = var.VPC["SUBNET_DB"]

  enable_nat_gateway = false
  single_nat_gateway = false
  enable_vpn_gateway = false
  
  # default_vpc_enable_dns_support = true
  # default_vpc_enable_dns_hostnames = true
  
  enable_dns_support = true
  enable_dns_hostnames = true
}

# module "vpc_endpoints" {
#   source = "./modules/vpc/modules/vpc-endpoints"

#   vpc_id = module.vpc.vpc_id

#   endpoints = {
#     ecr_api = {
#       service             = "ecr.api"
#       private_dns_enabled = true
#       subnet_ids          = module.vpc.public_subnets
#       policy              = data.aws_iam_policy_document.generic_endpoint_policy.json
#     },
#     ecr_dkr = {
#       service             = "ecr.dkr"
#       private_dns_enabled = true
#       subnet_ids          = module.vpc.public_subnets
#       policy              = data.aws_iam_policy_document.generic_endpoint_policy.json
#     }
#   }
# }

# data "aws_iam_policy_document" "generic_endpoint_policy" {
#   statement {
#     effect    = "Allow"
#     actions   = ["*"]
#     resources = ["*"]

#     principals {
#       type        = "*"
#       identifiers = ["*"]
#     }

#     condition {
#       test     = "StringNotEquals"
#       variable = "aws:SourceVpc"

#       values = [module.vpc.vpc_id]
#     }
#   }
# }



# =================== ============================== Target Group =================================================
# resource "aws_lb_target_group" "targetGroup" {
#   name             = "ammar-TG"
#   port             = 80
#   protocol         = "HTTP"
#   protocol_version = "HTTP1"
#   target_type      = "ip"
#   vpc_id           = module.vpc.vpc_id

#   health_check {
#     enabled             = true
#     healthy_threshold   = 5
#     interval            = 30
#     matcher             = 200
#     path                = "/"
#     protocol            = "HTTP"
#     timeout             = 5
#     unhealthy_threshold = 2
#   }


#   depends_on = [
#     module.vpc
#   ]
# }


# ================================================= Load Balancer =================================================
# resource "aws_lb" "load_balancer" {
#   name                             = "ammar-ALB"
#   load_balancer_type               = "application"
#   internal                         = false
#   security_groups                  = [module.vpc.default_security_group_id]
#   ip_address_type                  = "ipv4"
#   subnets                          = module.vpc.public_subnets
#   enable_deletion_protection       = true

#   idle_timeout = 600

# }


# ================================================= Load Balancer Listeners =================================================
# resource "aws_lb_listener" "port_80" {
#   load_balancer_arn = aws_lb.load_balancer.arn
#   port              = 80
#   protocol          = "HTTP"

#   default_action {
#     type = "redirect"
    
#     redirect {
#       port        = "443"
#       protocol    = "HTTPS"
#       status_code = "HTTP_301"
#     }
#   }

#   depends_on = [
#     aws_lb.load_balancer
#   ]
# }


# data "aws_iam_policy_document" "cost_usage_report_policy" {
#     statement {
#     effect = "Allow"

#     actions = [
#       "cur:DescribeReportDefinitions",
#       "cur:PutReportDefinition",
#       "cur:ModifyReportDefinition",
#       "cur:DeleteReportDefinition",
#       "cur:ListReportDefinitions"
#     ]

#     resources = ["*"]
#   }

#   statement {
#     effect = "Allow"

#     actions = [
#       "ce:GetCostAndUsage",
#       "ce:GetAnomalySubscriptions",
#       "ce:GetAnomalies",
#       "ce:DescribeAnomalyMonitors",
#       "ce:GetAnomalyMonitors",
#       "ce:CreateAnomalyMonitor",
#       "ce:DeleteAnomalyMonitor"
#     ]

#     resources = ["*"]
#   }
  
#   statement {
#     effect = "Allow"

#     actions = [
#       "lambda:Get*",
#       "lambda:List*"
#     ]

#     resources = ["*"]
#   }

#   statement {
#     effect = "Allow"

#     actions = [
#       "rds:Describe*"
#     ]

#     resources = ["*"]
#   }
# }

# output "name" {
#   value = data.aws_iam_policy_document.cost_usage_report_policy.json
# }

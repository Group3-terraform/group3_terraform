project_name = "group3"
environment  = "uat"

cluster_version = "1.34"

azs = [
  "ap-southeast-1a",
  "ap-southeast-1b",
]

public_subnets = [
  "10.0.0.0/20",
  "10.0.16.0/20",
]

private_subnets = [
  "10.0.32.0/20",
  "10.0.48.0/20",
]

hosted_zone_id  = "Z07852252OWMU8O090PPL"

zone_id = "Z07852252OWMU8O090PPL"

domain          = "theareak.click"
subdomain       = "api.uat"

node_min     = 1
node_desired = 1
node_max     = 2


aws_region = "ap-southeast-1"


tls_secret_name = "theareak-tls"

service_a_image = "570430250751.dkr.ecr.ap-southeast-1.amazonaws.com/service-a:dev-v1.0.16"
service_b_image = "570430250751.dkr.ecr.ap-southeast-1.amazonaws.com/service-b:dev-v1.0.12"
service_c_image = "570430250751.dkr.ecr.ap-southeast-1.amazonaws.com/service-c:dev-v1.0.12"

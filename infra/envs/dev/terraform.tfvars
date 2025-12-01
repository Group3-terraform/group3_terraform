project_name = "group3"
environment  = "dev"

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

node_min     = 1
node_desired = 1
node_max     = 2

domain          = "api.dev.theareak.click"
tls_secret_name = "theareak-tls"

service_a_image = "570430250751.dkr.ecr.ap-southeast-1.amazonaws.com/service-a:latest"
service_b_image = "570430250751.dkr.ecr.ap-southeast-1.amazonaws.com/service-b:latest"
service_c_image = "570430250751.dkr.ecr.ap-southeast-1.amazonaws.com/service-c:latest"

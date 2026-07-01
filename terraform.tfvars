aws_region       = "us-east-1"
instance_type    = "t3.micro"
key_name         = "your-existing-keypair-name" # CHANGE ME
instance_name    = "ubuntu-ec2-instance"
allowed_ssh_cidr = "0.0.0.0/0" # CHANGE ME to your own IP, e.g. "203.0.113.5/32"

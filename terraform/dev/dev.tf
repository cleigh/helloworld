terraform {
    backend "s3" {
        bucket = "iac-nonprod-tfstate"
        key = "dev"
        region = "us-gov-west-1"
    
    }
}

module "instances" {
  source = "../modules"
  ENV = "dev"
}




data "aws_ami" "ice_non_prod"{
  most_recent = true
  filter{
    name = "name"
    values = ["ICE RHEL*"]
  }

  filter{
    name = "tag:Environment"
    values = ["Non-Production"]
  }
  
  owners =["263408170269"]
}




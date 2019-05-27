#Profile to be used during the provisioning

variable "ENV" {}

#VPC where the EC2 instance will be deployed
variable "vpc_id"  {
  default = "vpc-6b07db0e"
}

#Subnet in the VPC
variable "subnet_id" {
  default = "subnet-ac793dc9"
}

#ICE RHEL 7.4 Image
variable "ami" {
 default = "ami-06f06c67"
}

#EC2 instance type
variable "instance_type" {
  default = "t2.large"
}

#OS Disk Size
variable "OSDiskSize" {
  default = "100"
}

#Data Disk Size
variable "DataDiskSize" {
  default = "100"
}

#ICE key
variable "key_name" {
  default = "ec2-ice-mgmt"
}

#Management SG - Make sure port 3389 is open so you can RDP into the Instance
variable "vpc_security_group_ids" {
  default = "sg-84a2ebe0"
}


data "aws_ami" "ice_non_prod"{

  most_recent = true
  filter{
    name = "name"
    values = ["ICE RHEL*"]
  }

 
  owners =["263408170269"]
}

resource "aws_instance" "EC2Instance" {
  ami           = "${data.aws_ami.ice_non_prod.id}"
  instance_type = "${var.instance_type}"
  subnet_id = "${var.subnet_id}"
  key_name = "${var.key_name}"
  vpc_security_group_ids = ["${var.vpc_security_group_ids}"]
  root_block_device {
    volume_size = "${var.OSDiskSize}"
    volume_type = "gp2"
    delete_on_termination = true
  }
  /*
  ebs_block_device {
    device_name = "/dev/xvdb"
    volume_size = "${var.DataDiskSize}"
    volume_type = "gp2"
    delete_on_termination = true
    encrypted = true
  }
  */
   
   tags {
    Name = "${var.ENV == "dev" ? "w1idvappiac008" : "w1idvappiac009"}"
    Portfolio = "CIDO"
    ResourcePOC = "Richard.P.Inzunza@ice.dhs.gov"
    ApplicationGroup = "TOOLS"
    Application = "IAC"
    Environment = "DV"
    ResourceType = "Test"
    BillingCode = "192116CIOSDD20050"
    FISMAID = "NA"
   }

   user_data   = "${data.template_file.init.rendered}"
  
}


data "template_file" "init" {
  template = <<-EOF
              #!/bin/bash
              hostnamectl set-hostname "$${hostname}"
              EOF

  vars {
    hostname = "${var.ENV == "dev" ? "w1idvappiac008" : "w1idvappiac009"}.irmnet.ds2.dhs.gov"
  }
}

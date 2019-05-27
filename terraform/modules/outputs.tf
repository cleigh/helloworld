output "instance_ip"{
  value = "${aws_instance.EC2Instance.private_ip}"
}

output "app_hostname"{
  value = "${aws_instance.EC2Instance.tags.Name}"
}

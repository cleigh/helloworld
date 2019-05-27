output "app_ip" {
      value = "${module.instances.instance_ip}"
    }

output "hostname" {
      value = "${module.instances.app_hostname}"
    }
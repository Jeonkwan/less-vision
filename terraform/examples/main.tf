terraform {
  required_version = ">= 1.3"
}

variable "domain" {}
variable "email" {}
variable "uuid" {}
variable "host" {}
variable "user" {
  default = "ubuntu"
}

resource "null_resource" "xray" {
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = var.host
      user        = var.user
      agent       = true
      timeout     = "5m"
    }

    inline = [
      "sudo ansible-playbook -i /opt/less-vision/ansible/inventory/hosts.ini /opt/less-vision/ansible/playbooks/site.yml --extra-vars 'xray_domain=${var.domain} xray_email=${var.email} xray_uuid=${var.uuid}'"
    ]
  }
}

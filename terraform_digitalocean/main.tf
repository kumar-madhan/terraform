# main.tf
variable "do_token" {}
variable "image" {}
variable "ssh_key_name" {}
variable "fingerprint" {}

# Create a new tag
resource "digitalocean_tag" "server" {
  name = "admin"
}

# Configure the DigitalOcean provider
provider "digitalocean" {
  token = var.do_token
}

data "digitalocean_ssh_key" "existing_key" {
  name       = var.ssh_key_name # Provide a name for the resource
}

# Define a DigitalOcean Droplet
resource "digitalocean_droplet" "server" {
  # count  = 1
  name   = "server"#-${count.index}"
  region = "blr1"
  size   = "s-1vcpu-2gb"
  image  = var.image
  tags   = [digitalocean_tag.server.id] 
  
  # SSH key configuration
  ssh_keys = [data.digitalocean_ssh_key.existing_key.id]


  provisioner "remote-exec" {
    inline = [
    "mkdir /home/admin",
    "mkdir -p /home/admin/.ssh",
    "useradd -s /bin/bash --home /home/admin admin",
    "chown -R admin:admin /home/admin",
    "echo 'admin ALL=(ALL) NOPASSWD:ALL' | sudo tee -a /etc/sudoers",
    "echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDep4YEgvLLDDcmN8GgreVZfUQsa55I4TDzDrnhHdQCfb/I0gVpZRE3ZTerrJKuZwwGJdJQ/bG/bgKpXyn8BiyhwgaSido8tiUhJBbYHAJZ6EH4KBoHkMKD7quZ9weTBT+oy1KP5gSWheVsshdyrY0XsCLhloIsp2pvYlLBHkgKA1Jy2EGQ54CRExh+FfwBXHtqRNMzzM7LQK4ZIVwJUszxZZya8BdWeme4PyJrAnddAVVcgamJZlTNRjja32LZgKv+fqO6urjOcveRu4pAMeBWq2F7dExryhB1eq3O/33Dj9O7UivI5W5wIx+8T6APKugVNsEU9ePCuBfq9OCxNj6YQLg8+Xmi8fqRnclBiZOPx85L9s9jtuk/aUq/a1Z9mnE0Nu/lkqEEXeY+B0MSrKJMRkwmRVTH98KfxZRdq1e52z3cFRKXCiPqwC2jYbhewyHS0Z6hNzWnrkCFVRkAHdjqUSxOh5f6x8O66NNdZJhVBr/pbAJr4VNliKleJ8Hd6y0= madha@DESKTOP-76B27OU' >> /home/admin/.ssh/authorized_keys",
    "chmod 700 /home/admin/.ssh",
    "chmod 600 /home/admin/.ssh/authorized_keys",
    "echo 'root:admin' | sudo chpasswd",
    "echo 'admin:admin' | sudo chpasswd",
    # "sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config",
    "sudo systemctl restart sshd",
    
    # Additional commands such as installing packages can be added here
    "sudo yum install wget curl unzip net-tools firewalld -y",
    "sudo yum install epel-release -y"
  ]
    connection {
      type = "ssh"
      host = self.ipv4_address
      user = "root"
      private_key = file("~/.ssh/id_rsa")  # Path to your private key
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Delete resources if creation fails
resource "null_resource" "delete_resources" {
  triggers = {
    instance_id = digitalocean_droplet.server.id
  }

  provisioner "local-exec" {
    command = "echo 'Server creation failed.'"
    # Add additional cleanup commands if needed
  }

  depends_on = [digitalocean_droplet.server]
}

# Output the IP address of the Droplet
output "droplet_ip-1" {
  value = digitalocean_droplet.server.ipv4_address
}

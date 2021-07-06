# This is where you put your resource declaration
data "template_file" "user_data_hw" {
  # template = "${file("${path.module}/init.tpl")}"
   template = "${file("${path.root}/${var.init_tpl_file_name}")}"
}

resource "aws_instance" "ec2-webserver" {
  ami                         = var.ami_id
  associate_public_ip_address = true
  subnet_id                   = var.public_subnet_id
  root_block_device {
    volume_type = "gp2"
    volume_size = var.root_volume_size
    tags = {
      Name = "${var.project_name}-ROOT-BLK"
    }
  }
  instance_type          = var.instance_type
  # vpc_security_group_ids = [aws_security_group.webserver-sg-group.id]
  vpc_security_group_ids = [var.sec_grp_id]
  #   security_groups        = [aws_security_group.webserver-sg-group.id] dont use this , when you re run terraform, it will destory and will recreate the resources.
  # user_data = base64encode(data.template_file.user_data_hw.rendered)
  tags = merge(
    var.default_tags,
    {
      Name = "${var.project_name}-EC2"
    }
  )
  lifecycle {
    ignore_changes = [
      # Ignore changes to tags, e.g. because a management agent
      # updates these based on some ruleset managed elsewhere.
      tags,
    ]
  }
  key_name = var.pem_file_name_wo_dot_pem
}
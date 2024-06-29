module "jenkins" {
    source = "terraform-aws-modules/ec2-instance/aws"

    name  = "jenkins-tf"

    instance_type = "t3.small"
    vpc_security_group_ids = ["sg-0cd5626364cf1e071"]
    subnet_id = "subnet-0ff7989885902f665"
    ami = data.aws_ami.ami_info.id
    user_data = file("jenkins.sh")
    tags = {
        Name = "jenkins-tf"
    }
}

module "jenkins_agent" {
    source = "terraform-aws-modules/ec2-instance/aws"

    name = "jenkins-agent"

    instance_type = "t3.small"
    vpc_security_group_ids = ["sg-0cd5626364cf1e071"]
    #convert StringList to list and get first element
    subnet_id = "subnet-0ff7989885902f665"
    ami = data.aws_ami.ami_info.id
    user_data = file("jenkins-agent.sh")
    tags = {
        Name = "jenkins-agent"
    }
}

resource "aws_key_pair" "nexus" {
    key_name = "nexus"
    #you can paste the public key directly like this 
    #public_key = ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGOHPD8vl9F86BiNLZPIp2h9yZ9WB3fSV7mENbc1mC16 Neela Reddy@neela
    public_key = file("~/.ssh/nexus.pub")
    # ~mean windows home directory
}

module "nexus" {
    source = "terraform-aws-modules/ec2-instance/aws"

    name = "nexus"

    instance_type = "t3.medium"
    vpc_security_group_ids = ["sg-0cd5626364cf1e071"]
    #convert StringList to list and get first element
    subnet_id = "subnet-0ff7989885902f665"
    ami = data.aws_ami.nexus_ami_info.id
    key_name = aws_key_pair.nexus.key_name
    root_block_device = [
        {
            volume_type = "gp3"
            volume_size = 30
        }
    ]
    tags = {
        Name = "nexus"
    }
}

module "records" {
    source = "terraform-aws-modules/route53/aws//modules/records"
    version = "~> 2.0"

    zone_name = var.zone_name

    records = [
        {
            name = "jenkins"
            type = "A"
            ttl = 1
            records = [
                module.jenkins.public_ip
            ]
        },
        {
            name = "jenkins-agent"
            type = "A"
            ttl = 1
            records = [
                module.jenkins_agent.private_ip
            ]
        },
        {
            name = "nexus"
            type = "A"
            ttl = 1
            allow_overwrite = true
            records = [
                module.nexus.private_ip
            ]
        }
    ]
}
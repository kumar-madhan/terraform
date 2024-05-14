resource "aws_vpc" "my_vpc" {
    cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet_1"{
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = "10.0.0.0/24"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet_2" {
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1b"
    map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route_table" "my_rt" {
    vpc_id = aws_vpc.my_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
}

resource "aws_route_table_association" "route_table_1" {
    subnet_id = aws_subnet.subnet_1.id
    route_table_id = aws_route_table.my_rt.id
}

resource "aws_route_table_association" "route_table_2" {
    subnet_id = aws_subnet.subnet_2.id
    route_table_id = aws_route_table.my_rt.id
}

resource "aws_security_group" "sg_1" {
  name        = "allow_traffic"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.my_vpc.id
  
  ingress{
    description = "Web-Traffic"
    from_port        = 80
    to_port          = 80
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress{
    description = "SSH-Traffic"
    from_port        = 22
    to_port          = 22
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress{
    description = "Access Outer World"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

}

resource "aws_s3_bucket" "bucket_1" {
  bucket = "free-tier-s3-bucket-1352"
}

resource "aws_s3_bucket_public_access_block" "bucket_1_pub_access" {
  bucket = aws_s3_bucket.bucket_1.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "bucket_1_owner" {
  bucket = aws_s3_bucket.bucket_1.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "bucket_1_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.bucket_1_owner,
    aws_s3_bucket_public_access_block.bucket_1_pub_access,
  ]

  bucket = aws_s3_bucket.bucket_1.id
  acl    = "public-read"
}

resource "aws_instance" "web_server_1" {
    ami = "ami-04b70fa74e45c3917"
    instance_type = "t2.micro"
    security_groups = [aws_security_group.sg_1.id]
    subnet_id = aws_subnet.subnet_1.id
    user_data = base64encode(file("script.sh"))
}

resource "aws_instance" "web_server_2" {
    ami = "ami-04b70fa74e45c3917"
    instance_type = "t2.micro"
    security_groups = [aws_security_group.sg_1.id]
    subnet_id = aws_subnet.subnet_2.id
    user_data = base64encode(file("script.sh"))
}
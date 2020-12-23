terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.70"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "us-east-2"
}

resource "aws_api_gateway_rest_api" "api" {
  name        = "api"
  description = "Sample api"
}

resource "aws_api_gateway_resource" "apiRes" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "apiSampleRes"
}

resource "aws_api_gateway_method" "apiMethod" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.apiRes.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "apiIntegr" {
  rest_api_id          = aws_api_gateway_rest_api.api.id
  resource_id          = aws_api_gateway_resource.apiRes.id
  http_method          = aws_api_gateway_method.apiMethod.http_method
  type                 = "MOCK"

  request_parameters = {
    "integration.request.header.X-Authorization" = "'static'"
  }

  request_templates = {
    "application/xml" = <<EOF
{
   "body" : $input.json('$')
}
EOF
  }
}


resource "aws_instance" "example" {
  ami           = "ami-0dd9f0e7df0f0a138"
  instance_type = "t2.micro"
  user_data     = <<-EOF
                #! /bin/bash
                echo "<h2>Hopefully it works at least now....</h2>" > index.html
                nohup busybox httpd -f -p 8080 &
  EOF

  vpc_security_group_ids = [aws_security_group.security_group.id]

  tags = {
    Name = "web"
  }

}

resource "aws_dynamodb_table_item" "subject_grade_item" {
  table_name = aws_dynamodb_table.subject_grades.name
  hash_key   = aws_dynamodb_table.subject_grades.hash_key

  item = <<ITEM
{
  "SubjectName" : {"S":"ESSD"},
  "SubjectGrade" : {"N": "9"}
}
ITEM
}

resource "aws_dynamodb_table_item" "subject_grade_item2" {
  table_name = aws_dynamodb_table.subject_grades.name
  hash_key   = aws_dynamodb_table.subject_grades.hash_key

  item = <<ITEM
{
  "SubjectName" : {"S":"ADB"},
  "SubjectGrade" : {"N": "10"}
}
ITEM
}


resource "aws_dynamodb_table" "subject_grades" {
  name           = "grades"
  read_capacity  = 10
  write_capacity = 10
  hash_key       = "SubjectName"

  attribute {
    name = "SubjectName"
    type = "S"
  }

}


resource "aws_security_group" "security_group" {
  name = "terraform-asg"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "instance_ips" {
  value = aws_instance.example.*.public_ip
}

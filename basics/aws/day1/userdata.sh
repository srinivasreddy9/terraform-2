#!/bin/bash
echo "Hello From Terraform" > index.html
nohup busybox httpd -f -p 8080 &
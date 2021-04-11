resource "aws_instance" "banking-solution-instance" {
  count         = "${var.instance_count}"
  ami           = "${var.ami}"
  instance_type = "${var.instance_type}"
  key_name      = "ankitdasmohapatra"
  subnet_id     = flatten(var.subnet_id)[0]
  vpc_security_group_ids = "${var.security_group_ids}" 

  tags = {
    Name = "${var.server-name}-${count.index}"
  }
}

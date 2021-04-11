output instance_ids {
  description = "IDs of EC2 instances"
  value       = ["${aws_instance.banking-solution-instance.*.id}"]
}

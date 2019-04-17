output "public_ip_address" {
  value = "${aws_instance.test_VM.public_ip}"
}
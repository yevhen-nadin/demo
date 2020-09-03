output "zabbix_instance" {
  value = "${aws_instance.zabbix.public_dns}"
}
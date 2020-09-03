variable "region" {
  type    = "string"
  default = "eu-west-1"
}

variable "availability_zone" {
  type    = "string"
  default = "eu-west-1a"
}

variable "instance_type" {
  type    = "string"
  default = "t3.micro"
}

variable "vpc_cidr" {
  type    = "string"
  default = "10.37.0.0/24"
}

variable "ssh_key" {
  type    = "string"
  default = "nadin-key"
}

variable "allowed_ips" {
  type    = "list"
  default = ["85.223.209.18/32"]
}

variable "userdata" {
  default = <<EOF
#cloud-config
packages:
  - python-pip
write_files:
- content: | 
    ---
    roles:
      - name: geerlingguy.mysql
        version: 3.0.0
      - name: geerlingguy.apache
      - name: dj-wasabi.zabbix-server
      - name: dj-wasabi.zabbix-agent
      - name: dj-wasabi.zabbix-web
        version: 1.5.0
  path: /deploy/requirements.yml
- content: |
    ---
    - hosts: localhost
      roles:
        - { role: geerlingguy.apache }
        - role: geerlingguy.mysql
          mysql_databases:
            - name: zabbix
          mysql_users:
            - name: zabbix
              host: "localhost"
              password: zabbix
              priv: "zabbix.*:ALL"
        - role: dj-wasabi.zabbix-server
          zabbix_server_database: mysql
          zabbix_server_database_long: mysql
        - role: dj-wasabi.zabbix-web
          zabbix_url: zabbix.example.com
          zabbix_server_database: mysql
          zabbix_server_database_long: mysql
  path: /deploy/main.yml
runcmd:
  - pip install ansible zabbix-api ipaddr
  - /usr/local/bin/ansible-galaxy install -r /deploy/requirements.yml
  - HOME=/root /usr/local/bin/ansible-playbook /deploy/main.yml
  - /usr/sbin/a2dissite 000-default
  - /usr/sbin/a2dissite vhosts
  - systemctl reload apache2
EOF
}
#cloud-config

hostname: jumphost
fqdn: ${fqdn}

users:
  - name: ubuntu
    groups:
      - sudo
      - docker
    shell: /bin/bash
    ssh_authorized_keys:
      - ${ssh_public_key}
    # review the following line from a security perspective.
    sudo: ALL=(ALL) NOPASSWD:ALL

package_update: true
packages:
  - net-tools
  - curl
  - htop
  - openssh-server
  - docker.io
  - gnupg
  - software-properties-common
  - golang
  - npm
  - nodejs
  - unzip
  - kubectx
  - emacs
  - vim
  - tmate
  - fzf
  - dc
  - mosh
  - wireguard
 
# This ubuntu image by default comes up with dysfunctional DNS
# lookups. This bootcmd sequence is a workaround.
  
bootcmd:
  - systemctl stop systemd-resolved
  - systemctl disable systemd-resolved
  - systemctl mask systemd-resolved
  - rm /etc/resolv.conf
  - echo nameserver 8.8.8.8 > /etc/resolv.conf
  - echo 127.0.0.1 jumphost.localdomain jumphost >> /etc/hosts
  - echo "${fqdn}" > /etc/fqdn

runcmd:
  - systemctl enable --now ssh || systemctl enable --now sshd
  - sudo -u ubuntu bash -c 'ssh-keygen -N "" < /dev/zero'
  - echo "done" > /tmp/cloud-config.done

timezone: Europe/Berlin
keyboard:
  layout: de
  variant: ""

# The following allows password-only access in case ssh keys
# are not working for you. We use a strong password generated
# by terraform. It is recommended to disallow all
# password authentification for hardening.

ssh_pwauth: True
chpasswd:
  expire: false
  users:
  - name: ubuntu
    password: ${default_jumphost_password}
    type: text
  

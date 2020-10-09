#!/usr/bin/env bash
# install common packages

export DEBIAN_FRONTEND=noninteractive

echo 'net.ipv6.conf.default.disable_ipv6 = 1' > /etc/sysctl.d/20-ipv6-disable.conf
echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.d/20-ipv6-disable.conf
echo 'net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.d/20-ipv6-disable.conf
cat /etc/sysctl.d/20-ipv6-disable.conf; sysctl -p

apt-get update
apt-get install -fy lsof vim git openssh-server tree tcpdump libevent-2.0-5 file make sudo lsyncd screen wget python 

wget https://bootstrap.pypa.io/get-pip.py
python get-pip.py
yes | /usr/local/bin/pip install zulip

rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

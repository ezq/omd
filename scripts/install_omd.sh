#!/usr/bin/env bash

PACKAGENAME=omd-2.90-labs-edition
REPOVERSION=stable

export DEBIAN_FRONTEND=noninteractive
echo 'net.ipv6.conf.default.disable_ipv6 = 1' > /etc/sysctl.d/20-ipv6-disable.conf
echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.d/20-ipv6-disable.conf
echo 'net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.d/20-ipv6-disable.conf
cat /etc/sysctl.d/20-ipv6-disable.conf; sysctl -p

gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys F8C1CA08A57B9ED7 && gpg --armor --export F8C1CA08A57B9ED7 | apt-key add -
echo "deb http://labs.consol.de/repo/stable/debian $(cat /etc/os-release  | grep 'VERSION=' | tr '(' ')' | cut -d ')' -f2) main" > /etc/apt/sources.list.d/labs-consol-testing.list
apt-get update
apt-get install -y $PACKAGENAME
apt-get clean

rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
find /omd/versions/default/skel/etc/logrotate.d -type f -exec sed -i 's/rotate [0-9]*/rotate 0/' {} \;

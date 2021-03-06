#!/bin/bash
export PS4='+[${LINENO}:${FUNCNAME[0]}:$(basename "${BASH_SOURCE[0]}")] '
LOCATION_PATH="$( cd $(dirname ${BASH_SOURCE[0]}); pwd )"

# if ${SHELLOPTS} include "xtrace"
[[ "${SHELLOPTS}" =~ "xtrace" ]] && setx="-x" || setx="+x"
unsetx="+x"
# uncomment the next line to print all commands as they are executed.
#setx="-x"; unsetx="${setx}"

# https://docs.docker.com/install/linux/docker-ce/centos/#install-using-the-repository
yum -y install device-mapper-persistent-data
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum -y install docker-ce

# 使用 flannel 生成的参数(/run/flannel/docker)配置 docker0 网络
mkdir -p /etc/systemd/system/docker.service.d
cat >/etc/systemd/system/docker.service.d/override.conf <<\EOF
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd $DOCKER_OPT_BIP $DOCKER_OPT_MTU $DOCKER_OPT_IPMASQ
ExecStartPost=/sbin/iptables -P FORWARD ACCEPT
EOF

mkdir -p /etc/systemd/system/docker.service.d
cat >/etc/systemd/system/docker.service.d/proxy.conf <<EOF
[Service]
Environment="HTTP_PROXY=${HTTP_PROXY}"
Environment="HTTPS_PROXY=${HTTPS_PROXY}"
Environment="NO_PROXY=${NO_PROXY}"
EOF

mkdir /etc/docker
cp ${LOCATION_PATH}/etc/docker/daemon.json /etc/docker/

systemctl daemon-reload
systemctl enable docker

# -*- mode: ruby -*-
# vi: set ft=ruby :

# 安装必备插件：
# 1. 配置代理，需要 vagrant-proxyconf 插件
required_plugins = %w(vagrant-proxyconf)
plugins_to_install = required_plugins.select { |plugin| not Vagrant.has_plugin? plugin }
if not plugins_to_install.empty?
  puts "Installing plugins: #{plugins_to_install.join(' ')}"
  if system "vagrant plugin install #{plugins_to_install.join(' ')}"
    exec "vagrant #{ARGV.join(' ')}"
  else
    abort "Installation of one or more plugins has failed. Aborting."
  end
end

# https://www.vagrantup.com/docs/vagrantfile/tips.html#overwrite-host-locale-in-ssh-session
ENV["LC_ALL"] = "en_US.UTF-8"

#
$num_instances = 3
$instance_name_prefix = "node"
$vm_gui = false
$vm_memory = 1024
$vm_cpus = 2
$shared_folders = {}
$forwarded_ports = {}

Vagrant.configure("2") do |config|

  config.ssh.forward_agent = true

  config.vm.box = "centos/7"

  config.vm.box_check_update = false

  config.vm.provider :virtualbox do |vb|
    vb.gui = $vm_gui
    vb.memory = $vm_memory
    vb.cpus = $vm_cpus
  end

  $shared_folders.each_with_index do |(host_folder, guest_folder), index|
    config.vm.synced_folder host_folder.to_s, guest_folder.to_s, id: "share-%02d" % index, nfs: true, mount_options: ['nolock,vers=3,udp']
  end

  $forwarded_ports.each do |guest, host|
    config.vm.network "forwarded_port", guest: guest, host: host, auto_correct: true
  end

  if Vagrant.has_plugin?("vagrant-proxyconf")
    #config.proxy.http     = "http://10.0.2.2:8080"
    #config.proxy.https    = "http://10.0.2.2:8080"
    #config.proxy.no_proxy = "10.0.2.2,10.0.2.15,127.0.0.1,localhost,.example.com"

    # https://github.com/tmatilai/vagrant-proxyconf#disabling-the-plugin
    # 通过 vagrant-proxyconf 插件配置 Docker 代理会顺带重启 Docker 服务，
    # 但 Docker 依赖的服务（etcd 及 flannel）并未成功运行，导致 Docker 重启失败，
    # 先去掉 Docker 代理，需要时自定义配置。
    #config.proxy.enabled = { docker: false }
  end

  config.vm.provision "shell", inline: <<-SHELL
set -xe
export PS4='+[$LINENO]'

# no_proxy
cat >/etc/profile.d/zzz_no_proxy.sh <<\EOF
# Named 'zzz_no_proxy.sh', so it will be loaded finally, and overwrite Env variable 'no_proxy'.
export no_proxy=\\$(echo 172.17.0.{1..255} | sed "s/ /,/g")
export no_proxy=\\${no_proxy},10.0.2.2,10.0.2.15,127.0.0.1,localhost,.example.com
EOF
source /etc/profile.d/zzz_no_proxy.sh &>/dev/null

# 可能需要配置 Proxy 的 CA 证书
cat >/etc/pki/ca-trust/source/anchors/proxy.pem <<\EOF

EOF
update-ca-trust

# 禁用 selinux
setenforce Permissive || true
sed -i 's|^SELINUX=.*|SELINUX=disabled|' /etc/selinux/config

# 关闭 swap
swapoff -a
sed -i '/swap/{ s|^|#| }' /etc/fstab

#yum -y update
yum -y install tcpdump

  SHELL

  # 根据节点的主机名和IP，生成 ETCD_INITIAL_CLUSTER
  etcd_cluster = Array.new
  (1..$num_instances).each do |i|
    etcd_cluster.push("%s-%02d=http://172.17.0.#{i+100}:2380" % [$instance_name_prefix, i, i])
  end
  ETCD_INITIAL_CLUSTER = etcd_cluster.join(",")

  (1..$num_instances).each do |i|
    config.vm.define vm_name = "%s-%02d" % [$instance_name_prefix, i] do |node|
      node.vm.hostname = vm_name

      ip = "172.17.0.#{i+100}"
      node.vm.network :private_network, ip: ip

      # 注：node.vm.provision 会在 config.vm.provision 之后执行 -- Vagrant enforces ordering outside-in
      node.vm.provision "shell" do |s|
        s.inline = <<-SHELL
set -xe
export PS4='+[$LINENO]'

bash /vagrant/provision/etcd.sh
bash /vagrant/provision/etcd_config.sh "$2" "$3" "$4"
bash /vagrant/provision/flannel.sh
bash /vagrant/provision/docker.sh

systemctl start etcd flanneld docker &

bash /vagrant/provision/kubernetes.sh "$3"

systemctl start kube-apiserver kube-controller-manager kube-scheduler kube-proxy kubelet &

bash /vagrant/provision/keepalived.sh

systemctl start keepalived &

        SHELL
        s.args = [i, vm_name, ip, ETCD_INITIAL_CLUSTER]    # 脚本中使用 $1, $2, $3... 读取
      end
    end
  end
end

# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

$nodes_num = (ENV['NODES_NUM'] || 1).to_i
$nodes_prefix = (ENV['NODES_PREFIX'] || "influx")
# OS image to use. Currently supported:
# - "ubuntu16" on openstack, virtualbox
# - "ubuntu14" on openstack, virtualbox
$os_image = (ENV['OS_IMAGE'] || "ubuntu14").to_sym

require "yaml"
if Vagrant.has_plugin?("vagrant-openstack-provider")
  require 'vagrant-openstack-provider'
end

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # By default, Vagrant 1.7+ automatically inserts a different
  # insecure keypair for each new VM created. The easiest way
  # to use the same keypair for all the machines is to disable
  # this feature and rely on the legacy insecure key.
  config.ssh.insert_key = true

  # This explicitly sets the order that vagrant will use by default if no --provider given
  config.vm.provider "virtualbox"
  config.vm.provider "openstack"

  # Do not update guest addition on the guest
  config.vbguest.auto_update = false

  # By default, Vagrant itself assumes that sudo requires no
  # password, therefore it does not need a tty. Some OS images
  # instead require a tty in order to run sudo.
  # Below configuration enable the tty on Vagrant 1.4+
  # See https://goo.gl/fC5sPW for details
  # config.ssh.pty = true

  def set_openstack_box(config)
    case $os_image
    when :ubuntu14
      # common config
      config.vm.box = "dummy"
      config.vm.box_url = "https://github.com/cloudbau/vagrant-openstack-plugin/raw/master/dummy.box"
    end
  end

  def set_vbox_box(config)
    case $os_image
    when :ubuntu16
      config.vm.box = "ubuntu/xenial64"
    when :ubuntu14
      config.vm.box = "ubuntu/trusty64"
    end
  end

  def set_openstack(os, config, n)
    set_openstack_box(config)

    # this crap is to make it not fail if the file doesn't exist (which is ok if we are using a different provisioner)
    __filename = File.join(File.dirname(__FILE__), "openstack_config.yml")
    if File.exist?(__filename)
      _config = YAML.load(File.open(__filename, File::RDONLY).read)
    else
      _config = Hash.new("")
      _config['security_group'] = []
    end

    config.ssh.username = _config["os_instance_username"]
    config.ssh.private_key_path = _config['os_ssh_pub_key_path']
    config.vm.boot_timeout = 60*10

    os.username         = _config['os_username']
    os.password         = ENV['OS_PASSWORD']
    os.tenant_name      = _config['os_tenant']
    os.keypair_name     = _config['os_ssh_key_name']
    os.openstack_auth_url = _config['os_auth_url']
    os.region           = _config['os_region_name']
    # os.floating_ip_pool = _config['os_floating_ip_pool']
    os.flavor           = _config['os_flavor']
    os.image            = _config['os_image']
    os.security_groups  = _config['os_security_groups']
    os.openstack_compute_url  = _config['os_openstack_compute_url']
    os.networks         = _config['os_networks']
    os.server_name = n.vm.hostname
  end

  def set_vbox(vb, config, vm_idx)
    set_vbox_box(config)

    config.vm.network "private_network", type: "dhcp"

    vb.gui = false
    vb.memory = 512
    vb.cpus = 1
  end

  def set_provider(n, vm_idx)
    n.vm.provider :openstack do |os, override|
      set_openstack(os, override, n)
    end
    n.vm.provider :virtualbox do |vb, override|
      set_vbox(vb, override, vm_idx)
    end
  end


  def run_shell_provision(n)
    # Enable provisioning with a shell script.
    n.vm.provider :openstack do |os, override|
      override.vm.provision "shell", inline: "/bin/bash /vagrant/provision.sh"
    end
    n.vm.provider :virtualbox do |vb, override|
      override.vm.provision "shell", inline: "/bin/bash /vagrant/provision.sh"
    end
  end

  def run_ansible_provision(n)
    # Enable provisioning with a shell script.
    n.vm.provider :openstack do |os, override|
      override.vm.provision "ansible" do |ansible|
        ansible.playbook = "install-influxdb.yml"
        ansible.sudo = true
      end
    end
    n.vm.provider :virtualbox do |vb, override|
      override.vm.provision "ansible" do |ansible|
        ansible.playbook = "install-influxdb.yml"
        ansible.sudo = true
      end
    end
  end

  nodes = Array.new()
  $nodes_num.times do |i|
    # multi vm config
    name = $nodes_prefix + "-#{i+1}"
    nodes.push(name)
    config.vm.define "#{name}" do |n|
      n.vm.hostname = name
      set_provider(n, i)
        # Provisioning
        run_ansible_provision(n)
    end
  end
end

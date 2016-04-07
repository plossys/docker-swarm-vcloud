# -*- mode: ruby -*-
# vi: set ft=ruby :

# Specify Vagrant version, Vagrant API version, and Vagrant clone location
Vagrant.require_version '>= 1.6.0'
VAGRANTFILE_API_VERSION = '2'

# Require 'yaml', 'fileutils', and 'erb' modules
require 'yaml'
require 'fileutils'
require 'erb'

# Read YAML file with VM details (box, CPU, RAM, IP addresses)
# Be sure to edit servers.yml to provide correct IP addresses
servers = YAML.load_file(File.join(File.dirname(__FILE__), 'servers.yml'))

# Build array of IP addresses for Consul cluster
consul_cluster_list = []
servers.each do |server|
  if server['name'].match(/^consul/)
    consul_cluster_list << "\"#{server['priv_ip']}\""
  end
end # servers.each

# Build a Consul configuration file from ERB template
template = File.join(File.dirname(__FILE__), 'server.json.erb')
content = ERB.new File.new(template).read
servers.each do |server|
  if server['name'].match(/^consul/)
    target = File.join(File.dirname(__FILE__), "#{server['name']}.json")
    File.open(target, 'w') { |f| f.write(content.result(binding)) }
  end
end # servers.each

# Create and configure the VMs
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # Always use Vagrant's default insecure key
  config.ssh.insert_key = false

  config.vm.provider :vcloud do |vcloud|
    vcloud.vapp_prefix = "docker-swarm"
    vcloud.ip_subnet = "192.168.1.1/255.255.255.0" # our test subnet with fixed IP adresses for everyone
    vcloud.ip_dns = ["10.100.20.2", "8.8.8.8"]  # SEAL DNS + Google
    vcloud.catalog_name = "COM-BUILD-CATALOG"
  end

  # Iterate through entries in YAML file to create VMs
  servers.each do |server|
    config.vm.define server['name'] do |srv|
      # Don't check for box updates
      srv.vm.box_check_update = false
      srv.vm.hostname = server['name']
      srv.vm.box = server['box']
      # Assign an additional static private network
      srv.vm.network 'private_network', ip: server['priv_ip']

      # Configure docker swarm box
      if server['name'].match(/^swarm/)
        srv.vm.provision 'shell', path: 'swarm.sh'
      end

      # Configure consul box
      if server['name'].match(/^consul/)
        srv.vm.provision 'shell', path: 'consul.sh'
      end

      # Configure VMs with RAM and CPUs per settings in servers.yml
      ["virtualbox", "vcloud", "vmware_fusion", "vmware_workstation"].each do |provider|
        srv.vm.provider provider do |v|
          v.memory = server['ram']
          v.cpus = server['vcpu']
        end
      end
    end # config.vm.define
  end # servers.each
end # Vagrant.configure

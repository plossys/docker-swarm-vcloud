# Running a Consul-Backed Docker Swarm Cluster in Vagrant

These files were created to allow users to use Vagrant ([http://www.vagrantup.com](http://www.vagrantup.com)) quickly and relatively easily spin up a Docker Swarm (URL) cluster backed by Consul ([http://www.consul.io](http://www.consul.io)). The configuration was tested using Vagrant 1.8.1, VMware vCloud plugin 0.4.4, VMware Fusion Pro 8.1.0, and the Vagrant VMware plugin.

## Contents

* **consul.conf**: This Upstart script is used to start the Consul agent and establish the Consul cluster. This file is copied to `/vagrant/consul.conf` by Vagrant's file provisioner, then moved to `/etc/init/consul.conf` by the `consul.sh` shell script called by Vagrant's shell provisioner.

* **consul.sh**: This shell script is executed by the Vagrant shell provisioner to create a Consul user, create directories needed by Consul, and provision the Ubuntu base box with the Consul binary. This shell script was written for an Ubuntu system; edits will likely be necessary for use with a different Linux distribution.

* **README.md**: This file you're currently reading.

* **server.json.erb**: This Consul configuration file contains configuration directives to run the Consul agent as a server. This file is copied to `/vagrant/${hostname}.json` by Vagrant's file provisioner, then moved to `/etc/consul.d/server/config.json` by `consul.sh` when called by Vagrant's shell provisioner. The IP addresses specified on the `retry_join` line in this file **must** match the IP address specified in `servers.yml`. If you change the IP addresses given to the VMs in `servers.yml`, you **must** also edit this file to make sure the addresses match.

* **servers.yml**: This YAML file contains a list of VM definitions. It is referenced by `Vagrantfile` when Vagrant instantiates the VMs. You will need to edit this file to provide appropriate IP addresses and other VM configuration data (see "Instructions" below).

* **swarm.sh.erb**: This script starts all the containers on a swarm VM.

* **Vagrantfile**: This file is used by Vagrant to spin up the virtual machines. This file is fairly extensively commented to help explain what's happening. You should be able to use this file unchanged; all the VM configuration options are stored outside this file.

## Instructions

These instructions assume you've already installed Vagrant, the Vagrant vCloud plugin, and your global Vagrantfile with your vCloud credentials and vOrg customizations. Please refer to the documentation for those products for more information on installation or configuration.

1. Use `vagrant box add` to install an Ubuntu 14.04 x64 box for the vcloud provider. I have a base box you can use for this purpose; to use my Ubuntu 14.04 x64 base box, add the box with `vagrant box add ubuntu1404 https://github.com/StefanScherer/vcloud-scenarios/raw/master/dummy_box/dummy.box`.

2. Place the files from the `docker-swarm` directory of this GitHub repository into a directory on your local system. You can clone the entire "learning-tools" repository (using `git clone`) or just download the specific files from the the `docker-swarm` folder.

3. Optionally, edit the `servers.yml` file to provide the specific details on the VMs that Vagrant should create. The `Vagrantfile` expects five values for each VM: `name` (the user-friendly name of the VM, which will also be used as the hostname for the guest OS inside the VM); `box` (the name of an Ubuntu 14.04 base box); `ram` (the amount of memory to be assigned to the VM); `vcpu` (the number of vCPUs that should be assigned to the VM); and `ip` (an IP address to be statically assigned to the VM and is used for Consul cluster communications). _It is not required to edit this file. You can use it without any modifications if desired._

5. Once you have edited `servers.yml` (and `server.json`, if you changed the IP addresses in `servers.yml`), use `vagrant up` to bring up the 6 systems. Three VMs will run the Consul cluster; the other 3 VMs will be running Ubuntu and will make up the Docker Swarm cluster.

6. Once Vagrant has finished bringing up the VMs, simply use `vagrant ssh consul-01` to login to the consul VM. Once Consul has been started on all three nodes, verify Consul is running correctly by running this command:

		consul members

	Consul should report three members, using the IP addresses specified in `servers.yml`. If Consul does not report three members (a minimum to bootstrap the cluster) or if it reports an error, you'll need to resolve this before continuing.

7. Use `vagrant ssh swarm-01` to log into the first Ubuntu system (`swarm-01` is the default name supplied in `servers.yml`; if you've changed the default name, modify your command appropriately).

8. Verify the operation of the Swarm cluster by running this command (from any system that has connectivity to the CoreOS system running the Swarm manager container launched in the previous step):

		docker -H tcp://192.168.1.5:8333 info

	Docker should return information indicating that there are 10 containers running across 3 nodes, and then provide more information about each node and the containers running on that node.

9. Launch an Nginx container somewhere on the cluster with this command:

		docker -H tcp://192.168.1.5:8333 run -d --name www -p 80:80 nginx

If everything is working as expected, Docker will launch an Nginx container on one of the CoreOS nodes in the Swarm cluster, and Registrator will register the presence of the container in Consul for service discovery.

Enjoy!

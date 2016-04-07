#!/bin/bash

if [ ! -e /usr/bin/docker ]; then
	curl https://get.docker.com | sh
	sudo usermod -aG docker vagrant
fi

function getmyip() { (tail -1 /etc/hosts | cut -f 1) }

docker kill consul registrator swarm manage
docker rm -vf consul registrator swarm manage

docker run -d -p 8300:8300 -p 8301:8301 -p 8301:8301/udp -p 8302:8302 -p 8302:8302/udp -p 8400:8400 -p 8500:8500 -p 8600:8600/udp --name consul -h $(hostname) progrium/consul -rejoin -advertise $(getmyip) -join 192.168.1.2

if [ $(hostname) == 'swarm-01' ]; then
	docker run -d --name registrator -h $(hostname) -v /var/run/docker.sock:/tmp/docker.sock gliderlabs/registrator consul://$(getmyip):8500
fi

docker run -d --name swarm swarm join --addr=$(getmyip):2375 consul://$(getmyip):8500/swarm

if [ $(hostname) == 'swarm-01' ]; then
	docker run -d -p 8333:2375 --name manage swarm manage consul://$(getmyip):8500/swarm
fi
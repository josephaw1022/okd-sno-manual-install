# Instructions and context

- Goal is setup an OKD cluster on a centos stream 10 server with 125gb of ram and 13 cpus
- The vms on the server will be created using libvirt and virt-manager
- The server is connected to the apartment network via a router that I control
- you are going to create a new git branch called `okd-libvirt-setup` and commit all changes to that branch
- you are going to modify the generate-install-config.sh, makefile, and some other scripts and files for okd installation


- you will need to generate the iso on this laptop and then we will write a playbook to copy it to the server
- then we create a playbook to create the vms with the iso and the args needed using libvirt

- dont worry about load balancing the api server or anything fancy like that for now, just get 3 master nodes for this cluster... keep it simple for now

- The apartment’s private Wi-Fi network uses the 172.16.0.0/12 range, which I can’t control. So I configured my private network on the router as follows:
- CIDR: 192.168.0.0/16
- Subnet Mask: 255.255.248.0

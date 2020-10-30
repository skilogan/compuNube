Vagrant.configure("2") do |config|
	Servers = 3

	(1..Servers).each do |i|
		config.vm.define "vma#{i}" do |mv|
			mv.vm.box = "bento/ubuntu-20.04"
			mv.vm.hostname = "vma#{i}"
			mv.vm.network :private_network, ip: "192.168.100.2#{i}"
			mv.vm.provision "shell", path: "vma#{i}.sh"
			mv.vm.synced_folder "carpetaCompartida", "/home/vagrant/carpetaCompartida"
			mv.vm.provider "virtualbox" do |v|
				v.name = "vma#{i}"
				v.memory = 1024
				v.cpus =1
			end
		end
	end
end

Vagrant.configure("2") do |config|

  config.vm.box = "debian/contrib-stretch64"
  config.vm.provision :shell, path: "VagrantProvision.sh"

  # MariaDB Port
  config.vm.network :forwarded_port, guest:3306, host: 3306

end

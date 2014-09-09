# install the server dependencies to run lxc
node[:lxc][:packages].each do |lxcpkg|
  package lxcpkg do
    if(node.platform_family?('debian'))
      options '-o Dpkg::Options::="--force-confold"'
    end
  end
end

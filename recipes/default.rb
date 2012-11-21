# install the server dependencies to run lxc
node[:lxc][:packages].each do |lxcpkg|
  package lxcpkg
end

include_recipe 'lxc::install_dependencies'

#if the server uses the apt::cacher-client recipe, re-use it
mirror="http://archive.ubuntu.com/ubuntu"
unless Chef::Config[:solo]
  if File.exists?('/etc/apt/apt.conf.d/01proxy')
    query = 'recipes:apt\:\:cacher-ng'
    query += " AND chef_environment:#{node.chef_environment}" if node['apt']['cacher-client']['restrict_environment']
    Chef::Log.debug("apt::cacher-client searching for '#{query}'")
    servers = search(:node, query)
    if servers.length > 0
      Chef::Log.info("apt-cacher-ng server found on #{servers[0]}.")
      mirror="http://#{servers[0]['ipaddress']}:3142/archive.ubuntu.com/ubuntu"
    end
  end
end

template '/etc/default/lxc' do
  source 'default-lxc.erb'
  mode 0644
end

#this just reloads the dnsmasq rules when settings may
#have been modified
service 'lxc-net' do
  action :enable
  subscribes :restart, resources(:template => '/etc/default/lxc')
end

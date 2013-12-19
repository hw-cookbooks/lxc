# -*- coding: utf-8 -*-

include_recipe 'lxc::bugfix_precise_repo'

dpkg_autostart 'lxc' do
  allow false
end

dpkg_autostart 'lxc-net' do
  allow false
end

# Start at 0 and increment up if found
unless(node[:network][:interfaces][:lxcbr0])
  max = node.network.interfaces.map do |int, info|
    info[:routes]
  end.flatten.compact.map do |routes|
    if(routes[:family].to_s == 'inet')
      val = (routes[:via] || routes[:destination])
      next unless val.start_with?('10.0')
      val.split('/').first.to_s.split('.')[3].to_i
    end
  end.flatten.compact.max

  node.default[:lxc][:network_device][:oct] = max ? max + 1 : 0

  # Test for existing bridge. Use different subnet if found
  l_net = "10.0.#{node[:lxc][:network_device][:oct]}"
  node.set[:lxc][:default_config][:lxc_addr] = "#{l_net}.1"
end

lxc_net_prefix = node[:lxc][:default_config][:lxc_addr].sub(%r{\.1$}, '')

Chef::Log.debug "Lxc net prefix: #{lxc_net_prefix}"

node.default[:lxc][:default_config][:lxc_network] = "#{lxc_net_prefix}.0/24"
node.set[:lxc][:default_config][:lxc_dhcp_range] = "#{lxc_net_prefix}.2,#{lxc_net_prefix}.254"
node.set[:lxc][:default_config][:lxc_dhcp_max] = '150'

file '/usr/local/bin/lxc-awesome-ephemeral' do
  action :delete
  only_if{ node[:lxc][:deprecated][:delete_awesome_ephemerals] }
end

# if the host uses the apt::cacher-client recipe, re-use it
# Is the host a cacher?
if(system("service apt-cacher-ng status 2>&1") && Chef::Config[:solo])
  node.default[:lxc][:default_config][:mirror] = "http://#{lxc_net_prefix}.1:3142/archive.ubuntu.com/ubuntu/"
elsif(File.exists?('/etc/apt/apt.conf.d/01proxy'))
  if(Chef::Config[:solo])
    proxy = File.readlines('/etc/apt/apt.conf.d/01proxy').detect do |line|
      line.include?('http::Proxy')
    end.to_s.split(' ').last.to_s.tr('";', '')
    unless(proxy.empty?)
      node.default[:lxc][:default_config][:mirror] = proxy
    end
  else
    query = 'recipes:apt\:\:cacher-ng'
    if(node[:apt]['cacher-client'][:restrict_environment])
      query += " AND chef_environment:#{node.chef_environment}"
    end
    Chef::Log.debug("apt::cacher-client searching for '#{query}'")
    servers = search(:node, query)
    unless(servers.empty?)
      Chef::Log.info("apt-cacher-ng server found on #{servers[0]}.")
      node.default[:lxc][:default_config][:mirror] = "http://#{servers.first['ipaddress']}:#{servers.first[:apt][:cacher_port] || 3142}/archive.ubuntu.com/ubuntu"
    end
  end
end

template '/etc/default/lxc' do
  source 'default-lxc.erb'
  mode 0644
end

include_recipe 'lxc::install_dependencies'

# install the server dependencies to run lxc
node[:lxc][:packages].each do |lxcpkg|
  package lxcpkg do
    options '-o Dpkg::Options::="--force-confold"'
  end
end

# use upstart on ubuntu > saucy
service_provider = Chef::Provider::Service::Upstart if 'ubuntu' == node['platform'] &&
  Chef::VersionConstraint.new('>= 13.10').include?(node['platform_version'])

# this just reloads the dnsmasq rules when the template is adjusted
service 'lxc-net' do
  provider service_provider
  action [:enable, :start]
  subscribes :restart, resources("template[/etc/default/lxc]")
end

service 'lxc' do
  provider service_provider
  action [:enable, :start]
end

chef_gem 'elecksee' do
  if(node[:lxc][:elecksee][:version_restriction])
    version node[:lxc][:elecksee][:version_restriction]
  end
  action node[:lxc][:elecksee][:action]
end

service 'lxc-apparmor' do
  service_name 'apparmor'
  action :nothing
end

file '/etc/apparmor.d/lxc/lxc-with-nesting' do
  path 'lxc-nesting.apparmor'
  mode 0644
  action node[:lxc][:apparmor][:enable_nested_containers] ? :create : :delete
  notifies :restart, 'service[lxc-apparmor]', :immediately
end

require 'elecksee/lxc'

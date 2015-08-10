package 'software-properties-common' do
  only_if{ node[:lxc][:enable_daily_ppa] }
end

execute 'enable lxc-daily ppa' do
  command 'apt-add-repository ppa:ubuntu-lxc/daily -y'
  only_if do
    node.platform_family?('debian') &&
      node[:lxc][:enable_daily_ppa]
  end
  not_if 'grep -R "^deb.*ppa.*lxc.daily" /etc/apt/sources.list*'
end

execute 'ppa update' do
  command 'apt-get update'
  action :nothing
  subscribes :run, 'execute[enable lxc-daily ppa]', :immediately
end

execute 'lxc ppa system upgrade' do
  command 'apt-get upgrade -yq'
  action :nothing
  subscribes :run, 'execute[enable lxc-daily ppa]', :immediately
  environment 'DEBIAN_FRONTEND' => 'noninteractive'
end

ruby_block 'ppa lxc package list' do
  block do
    node.default[:lxc][:packages] = node[:lxc][:ppa_packages]
  end
  action :nothing
  subscribes :create, 'execute[enable lxc-daily ppa]', :immediately
end

# install the server dependencies to run lxc
node[:lxc][:packages].each do |lxcpkg|
  package lxcpkg do
    subscribes :upgrade, 'execute[enable lxc-daily ppa]', :immediately
  end
end

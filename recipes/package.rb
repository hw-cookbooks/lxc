command 'enable lxc-daily ppa' do
  execute 'apt-add-repository ppa:ubuntu-lxc/daily -y'
  only_if do
    node.platform_family?('debian') &&
      node[:lxc][:enable_daily_ppa]
  end
  not_if 'grep -R "^deb.*ppa.*lxc.daily" sources.list*'
end

command 'ppa update' do
  execute 'apt-get update'
  action :nothing
  subscribes :run, 'command[enable lxc-daily ppa]', :immediately
end

# install the server dependencies to run lxc
node[:lxc][:packages].each do |lxcpkg|
  package lxcpkg
end

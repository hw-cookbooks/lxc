execute 'enable lxc-daily ppa' do
  command 'apt-add-repository ppa:ubuntu-lxc/daily -y'
  only_if do
    node.platform_family?('debian') &&
      node[:lxc][:enable_daily_ppa]
  end
  not_if 'grep -R "^deb.*ppa.*lxc.daily" sources.list*'
end

execute 'ppa update' do
  command 'apt-get update'
  action :nothing
  subscribes :run, 'command[enable lxc-daily ppa]', :immediately
end

# install the server dependencies to run lxc
node[:lxc][:packages].each do |lxcpkg|
  package lxcpkg do
    subscribes :upgrade, 'execute[ppa update]', :immediately
  end
end

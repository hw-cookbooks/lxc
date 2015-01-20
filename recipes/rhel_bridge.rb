
service 'cgconfig' do
  action [:enable, :start]
end

service 'cgred' do
  action [:enable, :start]
end

bridge_name = node[:lxc][:bridge]

execute "create #{bridge_name}" do
  command "brctl addbr #{bridge_name}"
  not_if "brctl showmacs #{bridge_name}"
end

file "/etc/sysconfig/network-scripts/ifcfg-#{bridge_name}" do
  content lazy{
    {
      :device => bridge_name,
      :type => 'Bridge',
      :bootproto => 'static',
      :ipaddr => node[:lxc][:addr],
      :netmask => node[:lxc][:netmask],
      :nm_controlled=> node[:lxc][:nm_controlled]
    }.map do |k,v|
      "#{k.to_s.upcase}=#{v.inspect}"
    end.join("\n")
  }
  mode 0644
  notifies :run, "execute[enable #{bridge_name}]", :immediately
end

execute "enable #{bridge_name}" do
  command "ifup #{bridge_name}"
  action :nothing
end

# @todo this is temp! don't leave this mess

file '/etc/sysconfig/iptables' do
  content [
    '# Chef managed to enable LXC',
    '*filter',
    ':INPUT ACCEPT [0:0]',
    ':FORWARD ACCEPT [0:0]',
    ':OUTPUT ACCEPT [0:0]',
    '-A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT',
    '-A INPUT -p icmp -j ACCEPT',
    '-A INPUT -i lo -j ACCEPT',
    '-A INPUT -m conntrack --ctstate NEW -m tcp -p tcp --dport 22 -j ACCEPT',
    'COMMIT',
    '',
    '*nat',
    ':PREROUTING ACCEPT [0:0]',
    ':OUTPUT ACCEPT [0:0]',
    ':POSTROUTING ACCEPT [0:0]',
    "-A POSTROUTING -s #{node[:lxc][:network]} ! -d #{node[:lxc][:network]} -j MASQUERADE",
    'COMMIT',
    ''
  ].join("\n")
  mode 0644
  notifies :restart, 'service[iptables]', :immediately
end

service 'iptables'

ruby_block 'enable ipv4 forwarding' do
  block do
    lines = File.readlines('/etc/sysctl.conf').map(&:strip)
    lines.delete_if{|l|l.empty?}
    line = lines.detect do |l|
      l.start_with?('net.ipv4.ip_forward')
    end
    if(line)
      line.replace('net.ipv4.ip_forward = 1')
    else
      lines << 'net.ipv4.ip_forward = 1'
    end
    File.open('/etc/sysctl.conf', 'w') do |file|
      file.puts lines.join("\n")
    end
  end
  not_if do
    File.readlines('/etc/sysctl.conf').include?('net.ipv4.ip_forward = 1')
  end
  notifies :run, 'execute[apply sysctl]', :immediately
end

execute 'apply sysctl' do
  command 'sysctl -p'
  action :nothing
end

package 'dnsmasq'

file '/etc/dnsmasq.conf' do
  content lazy{
    {
      'listen-address' => node[:lxc][:addr],
      'interface' => bridge_name,
      'except-interface' => 'lo',
      'bind-interfaces' => true,
      'dhcp-range' => "#{node[:lxc][:dhcp_range]}"
    }.map do |k,v|
      if(v == true)
        k
      else
        "#{k}=#{v}"
      end
    end.join("\n")
  }
  mode 0644
  notifies :restart, 'service[dnsmasq]', :immediately
end

service 'dnsmasq' do
  action [:enable, :start]
end

file '/etc/lxc/default.conf' do
  content [
    'lxc.network.type = veth',
    "lxc.network.link = #{bridge_name}",
    'lxc.network.flags = up',
    ''
  ].join("\n")
  mode 0644
end

default[:lxc][:config][:start_ipaddress] = nil
default[:lxc][:config][:validator_pem] = nil
default[:lxc][:config][:auto_start] = true
default[:lxc][:config][:bridge] = 'lxcbr0'
default[:lxc][:config][:use_bridge] = true
default[:lxc][:config][:addr] = '10.0.3.1'
default[:lxc][:config][:netmask] = '255.255.255.0'
default[:lxc][:config][:network] = '10.0.3.0/24'
default[:lxc][:config][:dhcp_range] = '10.0.3.2,10.0.3.254'
default[:lxc][:config][:dhcp_max] = '253'
default[:lxc][:config][:shutdown_timeout] = 120

default[:lxc][:allowed_types] = %w(debian ubuntu fedora)
default[:lxc][:container_directory] = '/var/lib/lxc'
default[:lxc][:dnsmasq_lease_file] = '/var/lib/misc/dnsmasq.leases'

default[:lxc][:knife] = {}
default[:lxc][:knife][:static_range] = ''
default[:lxc][:knife][:static_ips] = []

default[:lxc][:user_pass][:debian] = {:username => 'root', :password => 'root'}
default[:lxc][:user_pass][:ubuntu] = {:username => 'ubuntu', :password => 'ubuntu'}
default[:lxc][:user_pass][:fedora] = {:username => 'root', :password => 'root'}

default[:lxc][:packages] = %w(lxc)

default[:lxc][:containers] = {}

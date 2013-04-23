def load_current_resource
  @lxc = ::Lxc.new(
    new_resource.container,
    :base_dir => node[:lxc][:container_directory],
    :dnsmasq_lease_file => node[:lxc][:dnsmasq_lease_file]
  )
  @loaded ||= {}
  # value checks
  if(new_resource.device && !new_resource.dynamic)
    %w(address netmask).each do |key|
      raise ArgumentError.new("#{key} is required for static interfaces") if new_resource.send(key).nil?
    end
  end
  if(new_resource.device.nil? && new_resource.dynamic_configs.nil?)
    raise ArgumentError.new('Device must be defined when not using stanza attributes')
  end
  node.run_state[:lxc] ||= Mash.new
  node.run_state[:lxc][:interfaces] ||= Mash.new
  node.run_state[:lxc][:interfaces][new_resource.container] ||= []
  node.run_state[:lxc][:interfaces]["#{new_resource.container}_dynamics"] ||= []
end

action :create do
  raise 'Device is required for creating an LXC interface!' unless new_resource.device
  
  unless(@loaded[new_resource.container])
    @loaded[new_resource.container] = true
  end

  if(new_resource.device)
    net_set = Mash.new(:device => new_resource.device)
    if(new_resource.dynamic)
      net_set[:dynamic] = true
    else
      net_set[:auto] = new_resource.auto
      net_set[:address] = new_resource.address
      net_set[:gateway] = new_resource.gateway
      net_set[:netmask] = new_resource.netmask
      net_set[:up] = new_resource.up if new_resource.up
      net_set[:down] = new_resource.down if new_resource.down
      net_set[:ipv6] = new_resource.ipv6
    end

    node.run_state[:lxc][:interfaces][new_resource.container] << net_set
  end

  if(new_resource.dynamic_configs)
    node.run_state[:lxc][:interfaces]["#{new_resource.container}_dynamics"] += new_resource.dynamic_configs
  end
end

action :delete do
  # do nothing, simply not provided to run_state, and thus implicitly
  # deleted
end

require 'securerandom'

def load_current_resource

  if(new_resource.container)
    new_resource.utsname new_resource.container
  end
  unless(new_resource.struct[:utsname])
    new_resource.utsname new_resource.name
  end

  @lxc = ::Lxc.new(
    new_resource.utsname,
    :base_dir => node[:lxc][:container_directory],
    :dnsmasq_lease_file => node[:lxc][:dnsmasq_lease_file]
  )

  @config = ::Lxc::ConfigFile.new(@lxc.container_config.to_path)
end

action :create do
  _lxc = @lxc
  _config = @config

  directory @lxc.path.to_path do
    action :create
  end

  if(new_resource[:mount])
    file new_resource.mount do
      action :create
    end
  end

  if(new_resource.resource_style.to_s == 'merge')
    if(node[:lxc][:original_configs].nil?)
      node.set[:lxc][:original_configs] = []
      if(node[:lxc][:original_configs][new_resource.name].nil?)
        node.set[:lxc][:original_configs][new_resource.name] = _config.state_hash
      end
    end
    _config.state._merge!(new_resource.struct)
  else
    _config.state = new_resource.struct
  end

  file "lxc update_config[#{new_resource.utsname}]" do
    path _lxc.container_config.to_path
    content _config.generate_content
    mode 0644
  end
end

action :delete do
  _lxc = @lxc

  if(node[:lxc][:original_configs] && node[:lxc][:original_configs][new_resource.name])
    node.set[:lxc][:original_configs][new_resource.name] = nil
  end

  file "lxc delete_config[#{new_resource.name}]" do
    path _lxc.container_config.to_path
    action :delete
  end
end

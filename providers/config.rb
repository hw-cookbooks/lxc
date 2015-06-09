require 'securerandom'

def load_current_resource
  require 'elecksee/lxc_file_config'

  new_resource.utsname new_resource.container if new_resource.container
  new_resource.utsname new_resource.name unless new_resource.utsname

  @lxc = ::Lxc.new(
    new_resource.utsname,
    :base_dir => node[:lxc][:container_directory],
    :dnsmasq_lease_file => node[:lxc][:dnsmasq_lease_file]
  )

  new_resource.rootfs @lxc.rootfs.to_path unless new_resource.rootfs

  new_resource.default_bridge node[:lxc][:bridge] unless new_resource.default_bridge
  new_resource.mount @lxc.path.join('fstab').to_path unless new_resource.mount
  config = ::Lxc::FileConfig.new(@lxc.container_config)
  if((new_resource.network.nil? || new_resource.network.empty?))
    if(config.network.empty?)
      default_net = {
        :type => :veth,
        :link => new_resource.default_bridge,
        :flags => :up,
        :hwaddr => "00:16:3e#{SecureRandom.hex(3).gsub(/(..)/, ':\1')}"
      }
    else
      default_net = config.network.first
      default_net.delete(:ipv4) if default_net.has_key?(:ipv4)
      default_net.merge!(:link => new_resource.default_bridge)
    end
    new_resource.network(default_net)
  else
    [new_resource.network].flatten.each_with_index do |net_hash, idx|
      if(config.network[idx].nil? || config.network[idx][:hwaddr].nil?)
        net_hash[:hwaddr] ||= "00:16:3e#{SecureRandom.hex(3).gsub(/(..)/, ':\1')}"
      end
    end
  end
end

action :create do
  _lxc = @lxc

  directory @lxc.path.to_path do
    action :create
  end

  file new_resource.mount do
    action :create
    only_if do
      new_resource.mount == @lxc.path.join('fstab') &&
        !::File.exists?(@lxc.path.join('fstab'))
  end

  file "lxc update_config[#{new_resource.utsname}]" do
    path _lxc.container_config.to_path
    content ::Lxc::FileConfig.generate_config(new_resource)
    mode 0644
  end
end

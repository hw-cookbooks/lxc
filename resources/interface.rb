actions :create, :delete
default_action :create

attribute :container, :kind_of => String, :required => true

attr_accessor :dynamic_configs
def respond_to_this?(method)
  if(sym.to_s.match(%r{^(iface|mapping|auto|source|allow-)}))
    true
  end
end

if(Gem::Version.new(RUBY_VERSION.dup) >= Gem::Version.new('1.9.0'))
  def respond_to_missing?(method)
    super || respond_to_this?(method)
  end
else
  def respond_to?(method)
    super || respond_to_this?(method)
  end
end

# stanza attributes
def method_missing(sym, *args, &block)
  if(respond_to_this?(sym))
    process_interface_stanza(sym, *args, &block)
  else
    super
  end
end

def process_interface_stanza(name, *args, &block)
  @dynamic_configs ||= Mash.new
  key = [name, *args].map(&:to_s).join(' ')
  struct = Chef::Util::AttributeStruct.new
  struct.instance_exec(&block) if block
  @dynamic_configs[key] = struct._data
end

# deprecated attributes
attribute :device, :kind_of => String
attribute :auto, :kind_of => [TrueClass, FalseClass], :default => true
attribute :dynamic, :kind_of => [TrueClass, FalseClass], :default => false
attribute :address, :kind_of => String
attribute :gateway, :kind_of => String
attribute :up, :kind_of => String
attribute :down, :kind_of => String
attribute :netmask, :kind_of => [String,Numeric]
attribute :ipv6, :kind_of => [TrueClass,FalseClass], :default => false

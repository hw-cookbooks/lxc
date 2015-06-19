attr_reader :struct

actions :create, :delete
default_action :create

attribute :container, :kind_of => String, :default => nil # alias for utsname
attribute :resource_style, :equal_to => [:replace, :merge, 'replace', 'merge'], :default => :merge

def method_missing(*args, &block)
  unless(@struct)
    require 'elecksee/lxc_file_config'
    @struct = LxcStruct.new
    @struct._set_state(:value_collapse => true)
  end
  @struct.method_missing(*args, &block)
end

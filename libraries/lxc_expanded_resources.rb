module ChefLxc
  module Resource
    def cheflxc_initialize(*args)
      non_cheflxc_initialize(*args)
      @container = nil
    end

    def container(arg=nil)
      set_or_return(:container, arg, :kind_of => [String], :required => true)
    end

    def lxc
      @lxc ||= Lxc.new(
        @container,
        :base_dir => node[:lxc][:container_directory]
      )
    end

    def path(arg=nil)
      arg ? super(arg) : lxc.expand_path(super(arg))
    end

    def self.included(base)
      base.class_eval do
        alias_method :non_cheflxc_initialize, :initialize
        alias_method :initialize, :cheflxc_initialize
      end
    end
  end
end

class Chef
  class Resource
    class LxcTemplate < Template
      include ChefLxc::Resource
    end
    class LxcFile < File
      include ChefLxc::Resource
    end
  end
end

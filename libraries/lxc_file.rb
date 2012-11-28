class Chef
  class Resource
    class LxcFile < File
      def initialize(*args)
        super
        attribute(
          :container,
          :kind_of => String,
          :required => true
        )
      end

      def lxc
        @lxc ||= Lxc.new(
          @container,
          :base_dir => node[:lxc][:container_directory]
        )
      end

      def path(arg)
        super
      end

      def path
        @lxc.expand_path(super)
      end
    end
  end
end

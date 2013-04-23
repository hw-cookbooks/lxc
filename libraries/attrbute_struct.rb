require 'ostruct'

class Chef
  class Util
    class AttributeStruct < OpenStruct
      def method_missing(sym, *args, &block)
        if(!sym.to_s.end_with?('=') && !args.empty?)
          super("#{sym}=".to_sym, *args, &block)
        else
          super
        end
      end
    end
  end
end

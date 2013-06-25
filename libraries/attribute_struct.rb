require 'ostruct'

class Chef
  class Util
    class AttributeStruct < OpenStruct

      def initialize(*args, &block)
        super
      end

      def [](key)
        _data[key.to_sym]
      end
      
      def method_missing(sym, *args, &block)
        new_ostruct_member(sym)
        if(block)
          block_val = self.class.new
          block_val.instance_exec(&block)
        end
        if(!args.empty? || block)
          set_sym = sym.to_s.end_with?('=') ? sym : "#{sym}=".to_sym
          if(args.empty? && block)
            send(set_sym, block_val)
          elsif(!args.empty? && block)
            base = send(sym)
            base.send(args.first, block_val)
          else
            send(set_sym, args.first)
          end
        end
        send(sym)
      end

      # Custom to provide:
      # * settable without =
      # * auto nested structs
      def new_ostruct_member(name)
        name = name.to_sym
        unless(self.respond_to?(name))
          class << self; self; end.class_eval do
            define_method(name){|*args|
              if(args.empty?)
                unless(@table.has_key?(name))
                  @table[name] = AttributeStruct.new
                end
                @table[name]
              else
                send("#{name}=".to_sym, *args)
              end
            }
            define_method("#(name}="){|x| modifiable[name] = x }
          end
        end
        name
      end

      def _data
        @table
      end
    end
  end
end

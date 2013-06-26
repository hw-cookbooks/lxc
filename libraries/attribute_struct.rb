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
            # todo: iterate args (turtles all the way down!)
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
            define_method(name){|*args, &block|
              if(args.empty? && block.nil?)
                unless(@table.has_key?(name))
                  @table[name] = AttributeStruct.new
                end
                @table[name]
              else
                splat = args.empty? ? [nil] : args
                send("#{name}=".to_sym, *splat, &block)
              end
            }
            define_method("#{name}="){|x, &block|
              if(block)
                block_val = modifiable[name] || self.class.new
                block_val.instance_exec(&block)
              end
              if(block && x)
                modifiable[name].send(x, block_val)
              elsif(block)
                modifiable[name] = block_val
              else
                modifiable[name] = x
              end
            }
          end
        end
        name
      end

      def _data
        @table
      end

      def _dump
        __hashish[
          *(@table.map{|key, value|
            [key, value.is_a?(self.class) ? value._dump : value]
          }.flatten)
        ]
      end

      def _load(hashish)
        @table.clear if @table
        hashish.each do |key, value|
          if(value.is_a?(Hash))
            self.send(key)._load(value)
          else
            self.send(key, value)
          end
        end
        self
      end

      def __hashish
        defined?(Mash) ? Mash : Hash
      end
    end
  end
end

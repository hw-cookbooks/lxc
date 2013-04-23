require 'ostruct'

class Chef
  class Util
    class AttributeStruct < OpenStruct

      # TODO: nested handling:
      # * fubar.feebar.thing = 'hi'
      # * multiple exec blocks triggers error on define method
      def initialize(*args, &block)
        super
      end
      
      def method_missing(sym, *args, &block)
        if(!sym.to_s.end_with?('=') && !args.empty?)
          super("#{sym}=".to_sym, *args, &block)
        else
          new_ostruct_member(sym)
          send(sym)
        end
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
    end
  end
end

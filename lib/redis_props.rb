require 'redis_props/version'
require 'nest'
require 'active_support/concern'
require 'active_record'

module RedisProps
  extend ActiveSupport::Concern

  def r
    self.class.r[id]
  end
  protected :r

  module ClassMethods
    def r
      @redis_nest ||= Nest.new(name)
    end

    # Specifies a set of properties to be stored in Redis
    # for this ActiveRecord object instance.
    #
    # Options are:
    #   <tt>:defer</tt> - Specifies that the attributes in this context should be flushed
    #   to Redis only when the ActiveRecord object is saved. This option defaults to +false+
    #   and the default behavior is to read and write values to/from Redis immediately as
    #   they are accessed.
    #
    #   <tt>:touch</tt> - Specifies that this ActiveRecord object's +updated_at+ field should
    #   be updated on save (aka "touching the object") when you write new attributes values,
    #   even if no database-backed attributes were changed. This option is occasionally
    #   vital when dealing with cache invalidation in Rails. If you specify
    #   a symbol (vs :true), then that attribute will be updated with the current
    #   time instead of the updated_at/on attribute.
    #   This option defaults to +false+.
    #
    def props(context_name, opts={}, &block)
      PropsContext.new(context_name, self, opts, block)
    end
  end

  class PropsContext
    def initialize(context_name, klass, opts, block)
      @context_name, @klass, @opts = context_name, klass, opts
      instance_exec(&block)
    end

    def define(name, d_opts={})
      add_methods_to(@klass, "#{@context_name}_#{name}", d_opts, @opts)
    end

    private

    def add_methods_to(klass, d_name, d_opts, ctx_opts)
      klass.class_eval do
        define_method("#{d_name}") do
          instance_variable_get("@#{d_name}") || begin
            val = r[d_name].get
            val = val.nil? ? d_opts[:default] : PropsContext.typecaster(d_opts[:default]).call(val)
            instance_variable_set("@#{d_name}", val)
          end
        end
        define_method("#{d_name}?") do
          !!send(d_name)
        end
        define_method("#{d_name}=") do |val|
          instance_variable_set("@#{d_name}", val)
          r[d_name].set val.to_s
          if touch = ctx_opts[:touch]
            if touch == true
              if respond_to?(:updated_at)
                self.updated_at = Time.now
              elsif respond_to?(:updated_on)
                self.updated_at = Time.now
              else
                raise "updated timestamp column does not exist for use with the :touch option"
              end
            elsif respond_to? touch
              send("#{touch}=", Time.now)
            else
              raise "#{touch} timestamp column specified as :touch option does not exist"
            end
          end
        end
        after_destroy -> { r[d_name].del }
      end
    end

    def self.typecaster(default_value)
      case default_value
      when TrueClass, FalseClass
        @boolean ||= lambda {|v| v == "true"}
      when Float
        @float ||= lambda {|v| v.to_f }
      when Integer
        @integer ||= lambda {|v| v.to_i }
      when Range
        @range ||= lambda {|v| eval(v) }
      when Date
        @date ||= lambda {|v| ActiveRecord::ConnectionAdapters::Column.send(:string_to_date, v) }
      when Time
        @time ||= lambda {|v| ActiveRecord::ConnectionAdapters::Column.send(:string_to_time, v) }
      else
        lambda {|v| v}
      end
    end
  end
end

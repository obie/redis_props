require 'redis_props/version'
require 'redis-namespace'
require 'active_support/concern'
require 'active_record'

module RedisProps
  extend ActiveSupport::Concern
  extend self

  def reset!
    redis.del(*redis.keys) unless redis.keys.empty?
  end

  def redis
    @redis ||= Redis::Namespace.new("redis_props_#{Rails.env}", redis: $REDIS_SERVER)
  end

  module ClassMethods
    def redis_props(context_name="", &block)
      ctx = RedisPropertyContext.new(context_name)
      ctx.instance_exec(&block)
      ctx.add_methods_to(self)
    end
  end

  class RedisPropertyContext
    def initialize(context_name)
      @context_name = context_name
      @definitions = {}
    end

    def add_methods_to(klass)
      @definitions.each do |name, d|
        if (TrueClass === d.options[:default] || FalseClass === d.options[:default])
          kce = <<-end_eval
            def #{@context_name}_#{name}
              @#{@context_name}_#{name} ||= begin
                #puts "Accessing #{klass.name}:#{@context_name}_#{name}:\#{to_param}"
                r = redis.get("#{klass.name}:#{@context_name}_#{name}:\#{to_param}")
                r.nil? ? #{d.options[:default].to_s} : (r == "true" || r == "1")
              end
            end

            def #{@context_name}_#{name}?
              !!#{@context_name}_#{name}
            end

            def #{@context_name}_#{name}=(val)
              #puts "Setting #{klass.name}:#{@context_name}_#{name}:\#{to_param} to \#{val}"
              @#{@context_name}_#{name} = val
              redis.set "#{klass.name}:#{@context_name}_#{name}:\#{to_param}", val.to_s
            end
          end_eval
          klass.class_eval kce
        else
          klass.class_eval <<-end_eval
            def #{@context_name}_#{name}
              @#{@context_name}_#{name} ||= begin
                #puts "Accessing #{klass.name}:#{@context_name}_#{name}:\#{to_param}"
                redis.get("#{klass.name}:#{@context_name}_#{name}:\#{to_param}") || #{d.options[:default]}
              end
            end
            def #{@context_name}_#{name}=(val)
              #puts "Setting #{klass.name}:#{@context_name}_#{name}:\#{to_param} to \#{val}"
              @#{@context_name}_#{name} = val
              redis.set("#{klass.name}:#{@context_name}_#{name}:\#{to_param}", val.to_s)
            end
          end_eval
        end
        klass.class_eval <<-end_eval
          after_destroy lambda { redis.del("#{klass.name}:#{@context_name}_#{name}:\#{to_param}") }
        end_eval
      end
    end

    def define(name, options={})
      @definitions[name] = Definition.new(name, options)
    end
  end

  class Definition
    attr_reader :options
    def initialize(name, options)
      @name, @options = name, options
    end
  end
end

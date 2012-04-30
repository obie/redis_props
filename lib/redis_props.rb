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

    def redis_props(context_name, &block)
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
      @definitions.each do |definition_name, d|
        if (TrueClass === d.options[:default] || FalseClass === d.options[:default])
          kce = <<-end_eval
            def #{@context_name}_#{definition_name}
              @#{@context_name}_#{definition_name} ||= begin
                r[:#{@context_name}][:#{definition_name}].get.tap do |result|
                  result.nil? ? "#{d.options[:default].to_s}" : (result == "true" || result == "1")
                end
              end
            end

            def #{@context_name}_#{definition_name}?
              !!#{@context_name}_#{definition_name}
            end

            def #{@context_name}_#{definition_name}=(val)
              @#{@context_name}_#{definition_name} = val
              r[:#{@context_name}][:#{definition_name}].set val.to_s
            end
          end_eval
          klass.class_eval kce
        else
          klass.class_eval <<-end_eval
            def #{@context_name}_#{definition_name}
              @#{@context_name}_#{definition_name} ||= begin
                [:#{@context_name}][:#{definition_name}].get || "#{d.options[:default]}"
              end
            end
            def #{@context_name}_#{definition_name}=(val)
              @#{@context_name}_#{definition_name} = val
              r[:#{@context_name}][:#{definition_name}].set val.to_s
            end
          end_eval
        end
        klass.class_eval <<-end_eval
          after_destroy lambda { r[:#{@context_name}][:#{definition_name}].del }
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

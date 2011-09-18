require 'active_support/core_ext'

module ActiveDSL
  class Builder
    @@builds = nil
    @@callbacks = {}
    @@fields = {}
    @@has_many = {}

    def initialize(dsl_text = nil, &block)
      @values = {}
      @@has_many.each {|name, options| @values[name] = []}
      if block_given?
        instance_eval &block
      else
        instance_eval(dsl_text)
      end
    end

    def to_hash
      result = Hash.new
      @@fields.each {|name, options| result[name] = @values[name] }
      @@has_many.each {|name, options| result[name] = @values[name].map(&:to_hash) }
      return result
    end

    def to_instance
      @instance = @@builds.new

      @@fields.each do |name, options| 
        @instance.send("#{name}=", @values[name])
      end

      @@has_many.each do |name, options| 
        @instance.send("#{name}=", @values[name].map(&:to_instance))
      end

      if @@callbacks[:after_build_instance]
        @@callbacks[:after_build_instance].call(@instance)
      end
      
      @instance
    end

    def self.builds(klass)
      @@builds = klass
    end

    def self.after_build_instance(options = {}, &block)
      @@callbacks[:after_build_instance] = block
    end

    def self.field(name, options = {})
      @@fields[name] = options

      instance_eval do
        define_method(name) do |value|
          @values[name] = value
        end
      end
    end
    
    def self.has_many(name, options = {})
      @@has_many[name] = options

      singular = name.to_s.singularize
      builder_class = "#{singular}_builder".classify.constantize
      instance_eval do
        define_method(singular) do |&block|
          # @values[:components] ||= []
          @values[name] << builder_class.new(&block)
        end
      end
    end
  end
end

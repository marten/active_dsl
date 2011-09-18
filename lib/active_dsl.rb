require 'active_support/core_ext'

module ActiveDSL
  class Builder
    class InstanceClassNotSpecified < Exception; end

    class << self
      attr_accessor :class_to_build
      attr_accessor :callbacks
      attr_accessor :fields
      attr_accessor :has_many_relations
    end

    def initialize(dsl_text = nil, &block)
      @values = {}
      self.class.has_many_relations.each {|name, options| @values[name] = []} if self.class.has_many_relations

      instance_eval &block if block_given?
      instance_eval(dsl_text) if dsl_text
    end

    def to_hash
      result = Hash.new
      self.class.fields.each {|name, options| result[name] = @values[name] } if self.class.fields
      self.class.has_many_relations.each {|name, options| result[name] = @values[name].map(&:to_hash) } if self.class.has_many_relations
      return result
    end

    def to_instance
      raise InstanceClassNotSpecified unless self.class.class_to_build

      @instance = self.class.class_to_build.new

      self.class.fields.each do |name, options| 
        @instance.send("#{name}=", @values[name])
      end if self.class.fields

      self.class.has_many_relations.each do |name, options| 
        @instance.send("#{name}=", @values[name].map(&:to_instance))
      end if self.class.has_many_relations

      if self.class.callbacks[:after_build_instance]
        self.class.callbacks[:after_build_instance].call(@instance)
      end if self.class.callbacks
      
      return @instance
    end

    def self.builds(klass)
      self.class_to_build = klass
    end

    def self.after_build_instance(options = {}, &block)
      self.callbacks ||= {}
      self.callbacks[:after_build_instance] = block
    end

    def self.field(name, options = {})
      self.fields ||= {}
      self.fields[name] = options

      instance_eval do
        define_method(name) do |value|
          @values[name] = value
        end
      end
    end
    
    def self.has_many(name, options = {})
      self.has_many_relations ||= {}
      self.has_many_relations[name] = options

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

require 'active_support/core_ext'

module ActiveDSL
	class Factory
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
			factory_class = "#{singular}_factory".classify.constantize
			instance_eval do
				define_method(singular) do |&block|
				  # @values[:components] ||= []
          @values[name] << factory_class.new(&block)
				end
			end
		end
	end
end

module Politburo

	module DSL

		class ContextException < Exception
			def initialize(msg = nil, cause = nil)
				super(msg)
				@cause = cause
			end

			attr_reader :cause
		end

		class Context
			attr_reader :receiver

			def initialize(receiver)
				@receiver = receiver
			end

			def define(definition = nil, &block)
				instance_eval(definition) if definition
				instance_eval(&block) if block_given?

				receiver
			rescue => e
				raise ContextException.new("Error while evaluating DSL context. Underlying error is: #{e}\n\t#{e.backtrace.join("\n\t")}", e)
			end

			alias :evaluate :define

			def method_missing(method, *args)
				@receiver.send(method, *args)
			end

			def environment(attributes, &block)
				define_or_lookup_receiver(::Politburo::Resource::Environment, attributes, &block)
			end

			def node(attributes, &block)
				define_or_lookup_receiver(::Politburo::Resource::Node, attributes, &block)
			end

			def facet(attributes, &block)
				define_or_lookup_receiver(::Politburo::Resource::Facet, attributes, &block)
			end

			def state(attributes, &block)
				lookup_receiver(::Politburo::Resource::State, attributes, &block)
			end

			def remote_task(attributes, &block)
				define_or_lookup_receiver(::Politburo::Tasks::RemoteTask, attributes, &block)
			end

			def depends_on(state_context)
				receiver.add_dependency_on(state_context.receiver)
				state_context
			end

			def lookup(find_attrs)
				context = find_one_by_attributes(find_attrs)
				raise "Could not find receiver by attributes: #{find_attrs}." if (context.nil?) 
				context
			end

			def find_one_by_attributes(find_attrs)
				receivers = receiver.find_all_by_attributes(find_attrs)
				receivers.merge(receiver.parent_resource.find_all_by_attributes(find_attrs)) if (receivers.empty?) and (!receiver.parent_resource.nil?)
				if (receivers.empty?) and (!receiver.parent_resource.nil?)
					receivers.merge(receiver.root.find_all_by_attributes(find_attrs)) 
				end
				return nil if receivers.empty?

				raise "Ambiguous receiver for attributes: #{find_attrs}. Found: \"#{receivers.map(&:name).join("\", \"")}\"." if (receivers.size > 1) 
				receivers.first.context
			end

			protected

		  def validate!()
		    receiver.each { | r | r.validate! }
		  end

			private

			def find_attributes(new_receiver_class, name_or_attributes)
				attributes = name_or_attributes.respond_to?(:keys) ? name_or_attributes : { name: name_or_attributes }
				attributes.merge(:class => new_receiver_class)
			end

			def find_or_create_receiver(new_receiver_class, attributes, &block)
				receivers = find_by_attributes(find_attributes(new_receiver_class, name_or_attributes))
				raise "Ambiguous receiver for attributes: #{find_attrs.inspect}. Found: #{receivers.inspect}" if (receivers.size > 1) 

				return define_new_receiver(new_receiver_class, attributes, &block) if (receivers.empty?)

				context = receivers.first.context

				if (block_given?)
					context.define(&block)
				end

				return context
			end

			def define_or_lookup_receiver(new_receiver_class, attributes, &block)
				if (block_given?)
					# Definition
					define_new_receiver(new_receiver_class, attributes, &block)
				else
					# Lookup
					lookup_receiver(new_receiver_class, attributes, &block)
				end
			end

			def lookup_receiver(new_receiver_class, name_or_attributes, &block)
				context = lookup(find_attributes(new_receiver_class, name_or_attributes))
				receiver = context.receiver

				if (block_given?)
					context.define(&block)
				end

				context
			end

			def define_new_receiver(new_receiver_class, attributes, &block)
				new_receiver = new_receiver_class.new(attributes.merge(parent_resource: receiver))
				context = new_receiver.context
				context.define(&block)

				receiver.add_dependency_on(new_receiver)

				context
			end

		end

		def self.define(definition = nil, &block)
			root_resource = Politburo::Resource::Root.new(name: "")
			root_context = root_resource.context
			root_context.define(definition, &block)
			root_context.send(:validate!)

			root_resource
		end

	end

end
require 'politburo'

describe Politburo::Resource::Environment do

	let(:parent_resource) { Politburo::Resource::Base.new(name: 'Parent resource') }
	let(:environment) { Politburo::Resource::Environment.new(parent_resource: parent_resource, name: "Environment resource") }

  it("should have its own context class") { environment.context_class.should be Politburo::Resource::EnvironmentContext }

	it "should have all the default states" do
		parent_resource.states.each do | state | 
			state = environment.state(state.name)
			state.should_not be_nil
		end
	end
end

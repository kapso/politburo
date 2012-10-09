describe Politburo::Resource::State do

	let(:resource) { Politburo::Resource::Base.new(name: "Resource") }
	let(:state) { Politburo::Resource::State.new(resource: resource, name: "state") }
	let(:another_state) { Politburo::Resource::State.new(resource: resource, name: "another state") }
	
	it "should initialize with the resource it belongs to" do
		state.resource.should == resource
	end

	it "should require a name" do
		state.should be_valid

		state.name = nil
		state.should_not be_valid
	end

	it "should maintain a list of state dependencies" do
		state.dependencies.should be_empty

		state.dependencies << another_state

		state.dependencies.should_not be_empty
		state.dependencies.should include another_state
	end

	it "#add_dependency_on should work correctly" do
		state.dependencies.should be_empty
		state.add_dependency_on(another_state)

		state.dependencies.should_not be_empty
		state.dependencies.should include another_state
	end

	context "#add_dependency_on" do
		before :each do
			state.dependencies.should be_empty
			state.add_dependency_on(another_state)
			state.add_dependency_on(resource)
		end

		context "when target is a resource" do
			it "should add a dependency on the ready state of the target" do
				state.should be_dependent_on resource.state(:ready)
			end
		end

		context "when target is a state" do
			it "should add to the ready state a dependency on the state if the argument it is a state" do
				state.should be_dependent_on another_state
			end
		end
	end

	context "#full_name" do

		it "should be constructed of the resource full name and the state name" do
			state.full_name.should == "Resource#state"
		end

	end

	context "#to_task" do

		before :each do
			state.add_dependency_on(another_state)
		end

		let(:task) { state.to_task }

		it "should construct a task that depends on the task of any prerequisite states" do
			task.should_not be_nil
			task.prerequisites.first.state.should == another_state
		end

	end

	context "#dependent_on?" do+6

		before :each do
			state.dependencies << another_state
		end

		it "should return true if the state depends on the other specified state" do
			state.should be_dependent_on another_state
		end
		
		it "should return false if the state does not depends on the other specified state" do
			another_state.should_not be_dependent_on state
		end

	end

end
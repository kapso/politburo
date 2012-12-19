require 'politburo'

describe Politburo::Resource::Base do

	let(:parent_resource) { Politburo::Resource::Base.new(name: "Parent resource") }
	let(:resource) do 
		Politburo::Resource::Base.new(parent_resource: parent_resource, name: "Child resource")
	end

	let(:sub_resource_1) do
		Politburo::Resource::Base.new(parent_resource: resource, name: "Sub Resource 1")
	end

	let(:sub_resource_2) do
		Politburo::Resource::Base.new(parent_resource: resource, name: "Sub Resource 2")
	end

	it "should initialize with parent" do
		resource.parent_resource.should == parent_resource

		resource.should be_valid
	end

	it "should require a name" do
		resource.name = nil
		resource.should_not be_valid
	end

	it "should be searchable" do
		resource.should be_a Politburo::Resource::Searchable
	end

	context "#full_name" do
		it "should return a hierarchical name for the resource" do
			sub_resource_2.full_name.should == "Parent resource:Child resource:Sub Resource 2"
		end
	end

	context "#children" do

		it "should maintain a list of children" do
			parent_resource.children.should be_empty

			resource.should_not be_nil

			parent_resource.children.should_not be_empty
			parent_resource.children.length.should == 1
			parent_resource.children.first.should == resource

			resource.children.should be_empty
			sub_resource_1.should_not be_nil
			sub_resource_2.should_not be_nil

			resource.children.should_not be_empty
			resource.children.length.should == 2
			resource.children.should include(sub_resource_1)
			resource.children.should include(sub_resource_2)
		end
	end

	context "states" do

		it "should have minimum default states with their dependencies" do
			resource.states.should_not be_empty
			resource.state(:ready).should be_dependent_on resource.state(:configured) 
			resource.state(:configured).should be_dependent_on resource.state(:configuring)
		end

		context "#add_dependency_on" do
			let(:source) { Politburo::Resource::Base.new(name: 'Source') }
			let(:target) { double("target of dependency") }
			
 			context "when the target does not have states" do

				let (:ready_state) { double("ready_state") }

				it "should delegate to ready state's add_dependency_on with the target" do
					target.should_receive(:respond_to?).with(:states).and_return(false)
					source.should_receive(:state).with(:ready) { ready_state }
					ready_state.should_receive(:add_dependency_on) do | arg |
						arg.should be target
					end

					source.add_dependency_on(target)
				end
			end

			context "when the target has states," do
				before :each do
					target.should_receive(:respond_to?).with(:states).and_return(true)
				end

				let(:source_states) { Array.new(3) { | i | double("source state #{i}", name: "state_#{i}") } }

				it "should iterate over the source's states and add a dependency on the target state of the same name" do
					source.should_receive(:states).and_return(source_states)

					source_states.each do | source_state |
						target_state = double("Target's state: '#{source_state.name}'")

						target.should_receive(:state).with(source_state.name).and_return(target_state)

						source_state.should_receive(:add_dependency_on) do | dep_target |
								dep_target.should be target_state
						end
					end

					source.add_dependency_on(target)
				end

			end
		end

	end

	context "enumerable" do

		it "#each should yield self first, then states, then sub-resources breadth first" do
			sub_resource_1.should_not be_nil
			sub_resource_2.should_not be_nil

			each_a = parent_resource.to_a
			each_a.should_not be_empty
			each_a.first.should == parent_resource
			each_a.last.should == sub_resource_2.state(:terminated)

			expected_order = <<EXPECTED_ORDER
Parent resource
Parent resource#defined
Parent resource#created
Parent resource#starting
Parent resource#started
Parent resource#configuring
Parent resource#configured
Parent resource#ready
Parent resource#stopping
Parent resource#stopped
Parent resource#terminated
Parent resource:Child resource
Parent resource:Child resource#defined
Parent resource:Child resource#created
Parent resource:Child resource#starting
Parent resource:Child resource#started
Parent resource:Child resource#configuring
Parent resource:Child resource#configured
Parent resource:Child resource#ready
Parent resource:Child resource#stopping
Parent resource:Child resource#stopped
Parent resource:Child resource#terminated
Parent resource:Child resource:Sub Resource 1
Parent resource:Child resource:Sub Resource 1#defined
Parent resource:Child resource:Sub Resource 1#created
Parent resource:Child resource:Sub Resource 1#starting
Parent resource:Child resource:Sub Resource 1#started
Parent resource:Child resource:Sub Resource 1#configuring
Parent resource:Child resource:Sub Resource 1#configured
Parent resource:Child resource:Sub Resource 1#ready
Parent resource:Child resource:Sub Resource 1#stopping
Parent resource:Child resource:Sub Resource 1#stopped
Parent resource:Child resource:Sub Resource 1#terminated
Parent resource:Child resource:Sub Resource 2
Parent resource:Child resource:Sub Resource 2#defined
Parent resource:Child resource:Sub Resource 2#created
Parent resource:Child resource:Sub Resource 2#starting
Parent resource:Child resource:Sub Resource 2#started
Parent resource:Child resource:Sub Resource 2#configuring
Parent resource:Child resource:Sub Resource 2#configured
Parent resource:Child resource:Sub Resource 2#ready
Parent resource:Child resource:Sub Resource 2#stopping
Parent resource:Child resource:Sub Resource 2#stopped
Parent resource:Child resource:Sub Resource 2#terminated
EXPECTED_ORDER

			each_a.map(&:full_name).join("\n").strip.should == expected_order.strip
		end

	end

	context "searchable" do

		it "should be ::Searchable" do
			resource.should be_a Politburo::Resource::Searchable
		end

		context "#contained_searchables" do
			before :each do
				sub_resource_1.should_not be_nil
				sub_resource_2.should_not be_nil
				resource.children.should_not be_empty
			end

			it "should include both child resources and state resources" do
				resource.contained_searchables.length.should == 12
			end

			it "should include all child resources" do
				resource.contained_searchables.should include(sub_resource_1)
				resource.contained_searchables.should include(sub_resource_2)
			end

			it "should include all states resources" do
				resource.contained_searchables.should include(resource.state(:ready))

				resource.states.each do | state | 
					resource.contained_searchables.should include(state)
				end
			end
		end
	end

	context "#as_dependency" do

		it "should return ready state" do
			resource.as_dependency.should be resource.state(:ready)
		end

	end


	context "#root" do

		it "should return the root resource" do
			sub_resource_1.root.should == parent_resource
			sub_resource_2.root.should == parent_resource
			resource.root.should == parent_resource
			parent_resource.root.should == parent_resource
		end
	end

	context "logging" do

		it "should have a different default log formatter" do
			resource.log_formatter.call(Logger::ERROR, Time.now, "my prog", "error message").should include resource.full_name
		end
	end
end

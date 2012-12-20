require 'politburo'

describe "End to end test", :end_to_end => true do

  let (:cli) { Politburo::CLI.create(arguments) }

  let(:command_line) { "-e #{environment_definition_file} ##{state_to_achieve}" }
	let(:arguments) { command_line.split(/\s/) }

	describe "with Amazon environment" do
		let(:environment_definition_file) do
			File.join(File.dirname(__FILE__), "Amazon.envfile.rb")
		end

		let(:test_host) do
			cli.root.context.lookup(name: "Primary host in zone", region: 'ap-southeast-2')
		end

		context "#ready" do
			let(:state_to_achieve) { "ready" }

			it "should have an AWS cloud provider" do
				test_host.cloud_provider.should be_a Politburo::Resource::Cloud::AWSProvider
			end

			it "should run the envfile correctly" do
				test_host.should_not be_nil
				cli.run.should be_true

				test_host.cloud_server.should_not be_nil
				test_host.cloud_server.state.should == "running"
			end
		end

		context "#terminated" do
			let(:state_to_achieve) { "terminated" }

			it "should run the envfile correctly" do
				test_host.should_not be_nil
				cli.run.should be_true

				test_host.cloud_server.should_not be_nil
				test_host.cloud_server.state.should == "terminated"
			end
		end

	end
end
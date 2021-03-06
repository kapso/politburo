describe Politburo::Plugins::Cloud::Tasks::CreateTask do

  let(:provider) { double("cloud provider") }
  let(:node) { Politburo::Resource::Node.new(name: "Node resource") }

  let(:state) { node.context.define { state(:started) {} }.state(:started) }
  let(:task) { Politburo::Plugins::Cloud::Tasks::CreateTask.new(name: 'Create') }

  let(:cloud_server) { double("cloud server", display_name: 'server.display.name') }

  before :each do
    node.stub(:cloud_provider).and_return(provider)
    state.add_child(task)
  end

  context "#met?" do
    context "when the server has not been created yet" do
      it "should return false" do
        node.should_receive(:cloud_server).and_return(nil)
        task.should_not be_met
      end
    end

    context "when the server has been created" do

      before :each do
        node.should_receive(:cloud_server).and_return(cloud_server)
      end

      it "should return true" do
        task.should be_met
      end
    end
    
  end

  context "#verify_met?" do
    it "should delegate to met" do
      task.should_receive(:met?).with(true)

      task.verify_met?
    end
  end

  context "#meet" do

    it "should use find or create server to return the server" do
      provider.should_receive(:find_or_create_server_for).with(node).and_return(cloud_server)

      task.meet
    end
  end
end

require 'politburo'
require 'stringio'

describe Politburo::CLI do 

  context "#default_plugins" do

    it { Politburo::CLI.default_plugins.should be_a Set }
    
  end

  context "normal running" do

    let (:cli) { Politburo::CLI.new(options, targets) }
    let (:targets) { ['fake-target'] }
    let (:options) { { color: true } }

    let (:envfile_contents) do
      <<ENVFILE_CONTENTS
environment(name: "environment") do
  node(name: "node") { }
  node(name: "another node") do
    depends_on node(name: "node").state(:configured)
  end
  node(name: "yet another node") do
    state(name: 'configured').depends_on node(name: "node")
  end
end

environment(name: 'another environment') do
  node(name: "a node from another galaxy") {}
end
ENVFILE_CONTENTS
    end

    let(:node) { cli.root.find_all_by_attributes(name: :node).first }
    let(:another_node) { cli.root.find_all_by_attributes(name: "another node").first }
    let(:yet_another_node) { cli.root.find_all_by_attributes(name: "yet another node").first }
    let(:environment) { cli.root.find_all_by_attributes(name: 'environment').first }
    let(:another_environment) { cli.root.find_all_by_attributes(name: 'another environment').first }

    before(:each) do
      Kernel.stub(:exit).with(anything)
      cli.stub(:envfile_contents).and_return(envfile_contents)
      cli.log.stub(:debug)
      cli.log.stub(:trace)
      cli.log.stub(:info)
    end

    context "#root" do
      it "should parse the envfile contents into the root context" do
        cli.root.should_not be_nil
        cli.root.children.should include environment
        cli.root.children.should include another_environment
      end

    end

    context "#context" do
      it "should return the root context" do
        cli.root.should_receive(:context).and_return(:root_context)

        cli.context.should be :root_context
      end
    end

    context "#plugins" do
      let (:options) { { color: true, plugins: "Politburo::Plugins::Cloud::Plugin,   Integer" } }

      it "should resolve to the classes by name" do
        cli.plugins.should eq [ Politburo::Plugins::Cloud::Plugin, Integer ]
      end
    end

    context "#resolved_targets" do

      before :each do
        node.should_not be_nil
        another_node.should_not be_nil
        yet_another_node.should_not be_nil

        node.full_name.should eq("environment:node")

        cli.should_receive(:targets).and_return(targets)
      end

      context "when target names exist" do
        let(:targets) { ["environment:node", "environment:another node#ready", "environment:yet another node#configured"] }

        let(:resolved_targets) { cli.resolved_targets }
        
        it "should resolve the target names to the appropriate states" do
          resolved_targets.should include another_node.state(:ready)
          resolved_targets.should include yet_another_node.state(:configured)
          resolved_targets.should include node.state(:ready)
        end

        it "should return a set" do
          resolved_targets.should be_a Set
        end
      end

      context "when target names do not exist" do
        let(:targets) { ["environment:noodle", "environment:another node#ready", "environment:yet another node#configured"] }

        it "should raise an error" do
          lambda { cli.resolved_targets }.should raise_error("Could not resolve target: 'environment:noodle'.")
        end
      end

    end


    context "#private_keys_path" do

      let (:fake_private_keys_pathname) { double("fake private keys pathname") }

      before :each do
        cli.options.should_receive(:[]).with(:'private-keys-dir').and_return(:fake_private_keys_dir)
        File.should_receive(:expand_path).with(:fake_private_keys_dir).and_return(:fake_expanded_private_keys_dir)
        Pathname.should_receive(:new).with(:fake_expanded_private_keys_dir).and_return(fake_private_keys_pathname)
      end

      it "should use the private-keys-dir option to construct the key files dir" do
        fake_private_keys_pathname.should_receive(:directory?).and_return(true)

        cli.private_keys_path.should == fake_private_keys_pathname
      end

      it "should raise an error if the end result isn't a valid directory" do
        fake_private_keys_pathname.should_receive(:directory?).and_return(false)

        lambda { cli.private_keys_path}.should raise_error
      end

    end

    context "#run" do
      let(:targets) { ["environment:noodle", "environment:another node#ready", "environment:yet another node#configured"] }
      let(:node_ready_state) { node.state(:ready) }
      let(:another_node_ready_state) { another_node.state(:ready) }
      let(:resolved_targets) { Set.new([ node_ready_state, another_node_ready_state ]) }

      let(:node_ready_task) { double("node ready task") }
      let(:another_node_ready_task) { double("another ready task") }
      let(:tasks) { [ node_ready_task, another_node_ready_task ] }
      
      let(:runner) { double("runner", :run => true) }

      before(:each) do
        cli.stub(:resolved_targets).and_return(resolved_targets)
        node_ready_state.stub(:to_task).and_return(node_ready_task)
        another_node_ready_state.stub(:to_task).and_return(another_node_ready_task)
        Politburo::Dependencies::Runner.stub(:new).with(*tasks).and_return(runner)
      end

      it "should set the colorise flag on String" do
        String.should_receive(:allow_colors=).with(true)

        cli.run
      end

      it "should convert resolved targets to tasks" do
        cli.should_receive(:resolved_targets).and_return(resolved_targets)

        node_ready_state.should_receive(:to_task).and_return(node_ready_task)
        another_node_ready_state.should_receive(:to_task).and_return(another_node_ready_task)

        cli.run
      end

      context "when in interactive mode" do
        before :each do
          cli.options[:interactive] = true
        end

        it "should call pry on the cli" do
          cli.should_receive(:pry)

          cli.run
        end
      end

      context "when in non interactive mode" do
        it "should create a runner with the converted tasks and run it" do
          Politburo::Dependencies::Runner.should_receive(:new).with(*tasks).and_return(runner)
          runner.should_receive(:run).and_return(true)

          cli.run
        end

        context "when run failed" do

          it "should return false" do
            runner.should_receive(:run).and_return(false)
            cli.run.should be_false
          end

        end

        context "when run succeeds" do

          it "should return true" do
            runner.should_receive(:run).and_return(true)
            cli.run.should be_true
          end

        end
      end

      it "should call release" do
        cli.should_receive(:release)

        cli.run
      end
    end

    context "#release" do
      let(:fake_root) { double("root of envfile") }
      let(:fake_resource_a) { double("fake resource a") }
      let(:fake_resource_b) { double("fake resource b") }

      it "should iterate all resources (depth first) and call #release on each" do
        cli.should_receive(:root).and_return(fake_root)
        fake_root.should_receive(:each).and_yield(fake_resource_a).and_yield(fake_resource_b)
        fake_resource_a.should_receive(:release)
        fake_resource_b.should_receive(:release)

        cli.release
      end

    end

  end

  context "#create" do

    let (:cli) { 
      cli = nil; 
      capture(:stdout, :stderr) { 
        cli = Politburo::CLI.create(args) 
      }; 
      cli 
    }

    context "targets" do

      context "when provided" do
        let(:args) { %w(target1 target2#with-state target3#another-state) }

        it "should set the targets correctly" do
          cli.targets.should include "target1"
          cli.targets.should include "target2#with-state"
          cli.targets.should include "target3#another-state"
        end

      end

    end


    context "--envfile" do

      context "when not provided" do
        let(:args) { %w(fake-target) }

        it "should default to Envfile" do
          cli.options[:envfile].should == 'Envfile'
        end
      end

      context "when provided" do
        let(:args) { %w(--envfile=ProvidedEnvfile fake-target) }

        it "should set the envfile" do
          cli.options[:envfile].should == 'ProvidedEnvfile'
        end

      end

    end

    context "--private-keys-dir" do

      context "when not provided" do
        let(:args) { %w(fake-target) }

        it "should default to .ssh" do
          cli.options[:'private-keys-dir'].should == '.ssh'
        end
      end

      context "when provided" do
        let(:args) { %w(--private-keys-dir=Some-dir fake-target) }

        it "should set the source dir" do
          cli.options[:'private-keys-dir'].should == 'Some-dir'
        end

      end

    end

    it "should print help when no targets provided" do
      lambda { 
        capture(:stdout, :stderr) { 
          Politburo::CLI.create([]) 
        } 
      }.should raise_error SystemExit

      output.should_not be_nil
      output.should_not be_empty
      output.should include "politburo [options]"
      output.should include "--version"
      output.should include "--help"
    end

    it "should print version when asked, and exit" do
      lambda { 
        capture(:stdout, :stderr) { Politburo::CLI.create(%w(--version)) } 
      }.should raise_error SystemExit

      output.should_not be_nil
      output.should_not be_empty
      output.should include "politburo, version"
    end

  end

  let(:output_io) { StringIO.new }
  let(:output) { output_io.string }

  def capture(*streams)
    original_stderr = $stderr
    original_stdout = $stdout

    streams.map! { |stream| stream.to_s }
    begin
      streams.each do |stream| 
        begin
          eval "$#{stream} = output_io"
        rescue => e
          original_stdout.puts e
        end
      end
      yield
    ensure
      streams.each { |stream| eval("$#{stream} = #{stream.upcase}") }
      output
    end

  end


end
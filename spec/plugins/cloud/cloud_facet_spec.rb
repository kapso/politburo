describe Politburo::Plugins::Cloud::Facet do

  let(:parent_resource) { Politburo::Resource::Base.new(name: "Parent resource") }
  let(:facet) { Politburo::Plugins::Cloud::Facet.new(name: "Facet resource") }

  before :each do
    parent_resource.add_child(facet)
  end

  context "#provider" do

    it "should inherit provider" do
      parent_resource.should_receive(:provider).and_return(:simple)

      facet.provider.should be :simple
    end

    it "should require a provider" do
      parent_resource.should_receive(:provider).and_return(nil)
      facet.provider = nil
      facet.should_not be_valid
    end

  end

  context "#region" do

    it "should inherit region" do
      parent_resource.should_receive(:region).and_return(:us_west_1)

      facet.region.should be :us_west_1
    end

  end

  context "#provider_config" do

    it "should inherit provider_config" do
      parent_resource.should_receive(:provider_config).and_return(:config)

      facet.provider_config.should be :config
    end

  end
  
end

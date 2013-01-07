describe Politburo::Resource::Environment, "cloud extensions" do
  let(:parent_resource) { Politburo::Resource::Base.new(name: 'Parent resource') }
  let(:environment) { Politburo::Resource::Environment.new(parent_resource: parent_resource, name: "Environment resource") }

  it "should require an provider" do
    environment.provider = nil
    environment.should_not be_valid
  end

  it "should allow a region" do
    environment.region = :us_west_1
    environment.region.should be :us_west_1
  end

  it "should allow a provider configuration parameter" do
    environment.provider_config = {}
    environment.provider_config.should be {}
  end

end


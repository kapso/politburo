module Politburo
  module Plugins
    module Cloud
      class SecurityGroup < Politburo::Resource::Base
        include CloudResource
        implies {
          state(:created)     { create_and_define_resource(Politburo::Plugins::Cloud::Tasks::CloudResourceCreateTask,     name: "Create security group", noun: 'security group') {} } 
          state(:terminated)  { create_and_define_resource(Politburo::Plugins::Cloud::Tasks::CloudResourceTerminateTask,  name: "Delete security group", noun: 'security group') {} } 
        }

        def cloud_security_group
          cloud_provider.find_security_group_for(self)
        end

        def create_cloud_counterpart
          cloud_provider.create_security_group_for(self)
        end

        def cloud_counterpart
          cloud_security_group
        end

      end
    end
  end
end

module Politburo
  module Plugins
    module Cloud
      module Tasks
        class CloudResourceTerminateTask < Politburo::Resource::StateTask

          attr_accessor :noun

          def met?(verification = false)
            cloud_resource = resource.cloud_counterpart
            if cloud_resource.nil?
              logger.info("No #{noun}, so nothing to terminate.") unless verification
              return true
            end

            return false
          end

          def meet
            cloud_resource = resource.cloud_counterpart
            logger.info("Deleting #{noun}: #{cloud_resource.display_name.cyan}...")
            cloud_resource.destroy

            true
          end
        end
      end
    end
  end
end

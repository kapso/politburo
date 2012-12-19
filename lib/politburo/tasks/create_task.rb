module Politburo
  module Tasks
    class CreateTask < Politburo::Resource::StateTask

      def met?
        logger.info("Searching for existing server for node...")
        server = resource.cloud_server
        logger.info("\tIdentified existing server: #{server.dns_name.nil? ? server.id.cyan : server.dns_name.cyan}") if (server)
        server
      end

      def meet
        resource.cloud_provider.find_or_create_server_for(resource)
      end
    end
  end
end

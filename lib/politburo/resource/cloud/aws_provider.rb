module Politburo
  module Resource
    module Cloud
      class AWSProvider < Provider

        def self.config_for(resource)
          { provider: 'AWS' }.merge(resource.provider_config).merge(region: resource.availability_zone )
        end

        def find_server_for(node)
          matching_servers = compute_instance.servers.select do | s | 
            not s.tags.select { | k,v | k == "politburo:full_name" and v == node.full_name }.empty?
          end          

          return nil if matching_servers.empty?
          raise "More than one cloud server tagged with the full name: '#{node.full_name}'. Matching servers: #{matching_servers.inspect}" unless matching_servers.length == 1
          matching_servers.first
        end

        def create_server_for(node)
          server = compute_instance.servers.create(flavor_id: flavor_for(node), image_id: find_image(image_for(node)).id, name: "#{node.name}", tags: { "politburo:full_name" => node.full_name })
          server.wait_for { server.ready? }
        end

        def images
          @images ||= compute_instance.images
        end

        def find_image(image_selector)
          if image_selector.is_a?(String) or image_selector.is_a?(Symbol)
            attrs = {id: image_selector.to_s } 
          elsif image_selector.is_a?(Regexp)
            attrs = {name: image_selector } 
          else
            attrs = image_selector
          end

          images = find_images_by_attributes(attrs)

          raise "Could not find an image that matches the attributes: #{attrs}." if images.empty?
          raise "Ambiguous image identifier. More than one image matches the attributes: #{attrs}. Matches: #{images.inspect}" if images.size > 1

          images.first
        end

        def find_images_by_attributes(attributes)
          images.select { | image | Politburo::Resource::Searchable.matches?(image, attributes) }
        end

        def default_flavor
          "m1.small"
        end
      end
    end
  end
end

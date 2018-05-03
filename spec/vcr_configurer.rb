require 'vcr'
require 'active_support/core_ext/string'

module GoodData
  module Helpers
    # Configures VCR for integration tests
    class VcrConfigurer
      def self.name_to_placeholder(name)
        "<#{name.underscore.upcase}>"
      end

      def self.filter_body_field(vcr_config, part, field)
        placeholder = name_to_placeholder(field)
        vcr_config.filter_sensitive_data(placeholder) do |interaction|
          body_match = interaction[part].body.match(/"#{Regexp.quote(field)}":\s*"([^"]+)"/)
          body_match.captures.first if body_match
        end
      end

      def self.filter_header(vcr_config, part, header_name)
        placeholder = name_to_placeholder(header_name)
        vcr_config.filter_sensitive_data(placeholder) do |interaction|
          header = interaction[part].headers[header_name]
          header.first if header
        end
      end

      VCR.configure do |vcr_config|
        vcr_config.cassette_library_dir = 'spec/integration/vcr_cassettes'
        vcr_config.hook_into :webmock
        vcr_config.allow_http_connections_when_no_cassette = true
        vcr_config.configure_rspec_metadata!
        vcr_config.default_cassette_options = {
          :decode_compressed_response => true,
          :match_requests_on => [:path, :method, :query]
        }

        %w(request response).each do |part|
          filter_body_field(vcr_config, part, 'password')
          filter_body_field(vcr_config, part, 'token')
          filter_body_field(vcr_config, part, 'authorizationToken')
          filter_header(vcr_config, part, 'X-Gdc-Authsst')
          filter_header(vcr_config, part, 'X-Gdc-Authtt')
        end
      end
    end
  end
end

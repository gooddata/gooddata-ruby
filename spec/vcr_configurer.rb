require 'vcr'
require 'active_support/core_ext/string'

module GoodData
  module Helpers
    # Configures VCR for integration tests
    class VcrConfigurer
      VCR_PROJECT_ID = 'VCRFakeProjectId'
      VCR_SCHEDULE_ID = 'VCRFakeScheduleId'
      VCR_PROCESS_ID = 'VCRFakeProcessId'
      VCR_DATAPRODUCT_ID = 'VCRFakeDataProductId'
      @ignore_vcr_requests = false

      def self.setup
        gdc_path_matcher = lambda do |client_request, recorded_request|
          client_path = client_request.parsed_uri.path
          recorded_path = recorded_request.parsed_uri.path
          return true if matches_project_cache_fake_id?(client_path, recorded_path)

          uploads_regex = %r{(\/gdc\/uploads\/)[^\/]+(.*)}
          if client_path.match(uploads_regex) && recorded_path.match(uploads_regex)
            # custom path matcher, sanitizing the randomness of uploads dirs
            client_path.gsub(uploads_regex, '\1UPLOADS_TMP\2') == recorded_path.gsub(uploads_regex, '\1UPLOADS_TMP\2')
          else
            client_path == recorded_path
          end
        end

        VCR.configure do |vcr_config|
          vcr_config.cassette_library_dir = 'spec/integration/vcr_cassettes'
          vcr_config.hook_into :webmock
          vcr_config.allow_http_connections_when_no_cassette = true
          vcr_config.configure_rspec_metadata!

          vcr_config.ignore_request do
            @ignore_vcr_requests
          end

          vcr_config.default_cassette_options = {
            :decode_compressed_response => true,
            :match_requests_on => [gdc_path_matcher, :method, :query],
            # allow to set record mode from environment, see https://relishapp.com/vcr/vcr/v/3-0-3/docs/record-modes
            :record => vcr_record_mode
          }

          %w[request response].each do |part|
            filter_body_field(vcr_config, part, 'password')
            filter_body_field(vcr_config, part, 'token')
            filter_body_field(vcr_config, part, 'authorizationToken')
            filter_header(vcr_config, part, 'X-Gdc-Authsst')
            filter_header(vcr_config, part, 'X-Gdc-Authtt')
          end
        end

        if vcr_record_mode == :none
          # Fake project cache when running against VCR
          # because the IDs can be different every time.
          GoodData::Helpers::ProjectHelper.project_id = GoodData::Helpers::VcrConfigurer::VCR_PROJECT_ID
          GoodData::Helpers::ProjectHelper.schedule_id = GoodData::Helpers::VcrConfigurer::VCR_SCHEDULE_ID
          GoodData::Helpers::ProjectHelper.process_id = GoodData::Helpers::VcrConfigurer::VCR_PROCESS_ID
        end

        puts "VCR IS ON FOR THIS RUN IN MODE #{vcr_record_mode}"
      end

      def self.vcr_record_mode
        (ENV['VCR_RECORD_MODE'] && ENV['VCR_RECORD_MODE'].to_sym) || :none
      end

      def self.vcr_cassette_playing?
        VCR.current_cassette && !VCR.current_cassette.recording?
      end

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

      # Executes the passed block without recording requests.
      def self.without_vcr
        @ignore_vcr_requests = true
        yield
        @ignore_vcr_requests = false
      end

      private

      # Custom matcher that sanitizes the randomness
      # of the cached project and its objects.
      def self.matches_project_cache_fake_id?(actual_uri, recorded_uri)
        case actual_uri
        when Regexp.new(VCR_PROJECT_ID)
          %r{(/gdc/projects/)[^/]+(.*)} =~ recorded_uri
        when Regexp.new(VCR_PROCESS_ID)
          %r{(/gdc/projects/)[^/]+/dataload/processes/[^/]+} =~ recorded_uri
        when Regexp.new(VCR_SCHEDULE_ID)
          %r{(/gdc/projects/)[^/]+/schedules/[^/]+} =~ recorded_uri
        when Regexp.new(VCR_DATAPRODUCT_ID)
          %r{/gdc/domains/[^/]+/dataproducts/[^/]+} =~ recorded_uri
        end
      end
    end
  end
end

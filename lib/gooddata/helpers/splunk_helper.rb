require 'rest-client'
require 'nokogiri'


require_relative 'global_helpers'

module GoodData
  module Helpers
    module SplunkHelper
      class << self
        @@host = 'https://localhost:8089'
        @@paths = {
          :login => '/services/auth/login?cookie=1',
          :insert => '/services/receivers/simple'
        }

        def post(url_token, data, session_key = '', query = '')
          return RestClient::Request.execute( :method => 'post', :url => @@host+@@paths[url_token]+"?"+query, :payload => data, :verify_ssl => false, :headers => {
            "Authorization" => "Splunk "+session_key
          })
        end

        def get(url_token, session_key = '', query = '')
          return RestClient::Request.execute( :method => 'get', :url => @@host+@@paths[url_token]+"?"+query, :verify_ssl => false, :headers => {
            "Authorization" => "Splunk "+session_key
          })
        end


        def send_logs_as_csv(csv)
          login_payload = {
            'username'=>'admin',
            'password'=>'+ěšč'
          }

          response = post(:login, login_payload)

          xml = Nokogiri::XML(response.body)
          sessionKey = xml.at_xpath("//sessionKey").content

          puts csv

          post(:insert, csv, sessionKey, "source=api-call&sourcetype=ruby-statslog")

        end
      end
    end
  end
end


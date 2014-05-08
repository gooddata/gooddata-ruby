# encoding: UTF-8

require_relative 'connection'
require_relative '../extensions/hash'

module GoodData
  class PollingResult
    DEFAULT = {
      'wTaskStatus' => {
        'status' => 'RUNNING'
      }
    }

    PROJECT_ENABLED = {
      'project' => {
        'content' => {
          'state' => 'ENABLED'
        }
      }
    }
  end

  class << self
    def poll(result, key, options = {})
      sleep_interval = options[:sleep_interval] || 10
      link = result[key]['links']['poll']
      response = GoodData.get(link, :process => false)
      while response.code != 204
        sleep sleep_interval
        GoodData.connection.retryable(:tries => 3, :on => RestClient::InternalServerError) do
          sleep sleep_interval
          response = GoodData.get(link, :process => false)
        end
      end
    end

    def wait_for_polling_result(polling_url, done_matcher = PollingResult::DEFAULT)
      polling_result = GoodData.get(polling_url)
      while polling_result.deep_include?(done_matcher) == false
        sleep(3)
        polling_result = GoodData.get(polling_url)
      end
      polling_result
    end
  end
end

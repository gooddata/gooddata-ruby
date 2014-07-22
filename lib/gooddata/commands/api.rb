# encoding: UTF-8

require_relative '../exceptions/command_failed'

module GoodData
  module Command
    # Low level access to GoodData API
    class Api
      class << self
        def info
          json = {
            'releaseName' => 'N/A',
            'releaseDate' => 'N/A',
            'releaseNotesUri' => 'N/A'
          }

          puts 'GoodData API'
          puts "  Version: #{json['releaseName']}"
          puts "  Released: #{json['releaseDate']}"
          puts "  For more info see #{json['releaseNotesUri']}"
        end

        alias_method :index, :info

        # Test of login
        def test
          if GoodData.test_login
            puts "Succesfully logged in as #{GoodData.profile.user}"
          else
            puts 'Unable to log in to GoodData server!'
          end
        end

        # Get resource
        # @param path Resource path
        def get(path)
          fail(GoodData::CommandFailed, 'Specify the path you want to GET.') if path.nil?
          result = GoodData.get path
          begin
            result
          rescue
            puts result
          end
        end

        # Delete resource
        # @param path Resource path
        def delete(path)
          fail(GoodData::CommandFailed, 'Specify the path you want to DELETE.') if path.nil?
          result = GoodData.delete path
          begin
            result
          rescue
            puts result
          end
        end
      end
    end
  end
end

# encoding: UTF-8

module GoodData::Command
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

      alias :index :info

      def test
        if GoodData.test_login
          puts "Succesfully logged in as #{GoodData.profile.user}"
        else
          puts 'Unable to log in to GoodData server!'
        end
      end

      def get(path)
        raise(CommandFailed, 'Specify the path you want to GET.') if path.nil?
        result = GoodData.get path
        result rescue puts result
      end

      def delete(path)
        raise(CommandFailed, 'Specify the path you want to DELETE.') if path.nil?
        result = GoodData.delete path
        result rescue puts result
      end
    end
  end
end
module Gooddata::Command
  class Api < Base
    def info
      json = gooddata.release_info
      puts "GoodData API"
      puts "  Version: #{json['releaseName']}"
      puts "  Released: #{json['releaseDate']}"
      puts "  For more info see #{json['releaseNotesUri']}"
    end
    alias :index :info

    def test
      if gooddata.test_login
        puts "Succesfully logged in as #{gooddata.profile.user}"
      else
        puts "Unable to log in to GoodData server!"
      end
    end
  end
end
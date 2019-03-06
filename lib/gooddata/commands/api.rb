#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

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
        def get(args, opts)
          path = args.first
          fail(GoodData::CommandFailed, 'Specify the path you want to GET.') if path.nil?

          client = GoodData.connect(opts)
          client.get path
        end

        # Delete resource
        # @param path Resource path
        def delete(args, opts)
          path = args.first
          fail(GoodData::CommandFailed, 'Specify the path you want to DELETE.') if path.nil?

          client = GoodData.connect(opts)
          client.delete path
        end

        def post(args, opts)
          path = Array(args).shift
          fail(GoodData::CommandFailed, 'Specify the path you want to POST to.') if path.nil?

          payload = Array(args).shift
          json = payload && File.exist?(payload) ? JSON.parse(File.read(payload)) : {}
          client = GoodData.connect(opts)
          client.post path, json
        end
      end
    end
  end
end

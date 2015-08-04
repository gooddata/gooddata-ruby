# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'pp'
require 'hashie'

require_relative '../shared'
require_relative '../../commands/process'
require_relative '../../commands/runners'
require_relative '../../client'

# translate given params (with dots) to json-like params
def load_undot(filename)
  p = MultiJson.load(File.read(filename))
  GoodData::Helper.undot(GoodData::Helper::DeepMergeableHash[p])
end

GoodData::CLI.module_eval do
  desc 'Run ruby bricks either locally or remotely deployed on our server. Currently private alpha.'
  # arg_name 'show'
  command :run_ruby do |c|
    c.desc 'Directory of the ruby brick'
    c.default_value nil
    c.flag [:d, :dir]

    c.desc 'Log file. If empty STDOUT will be used instead'
    c.default_value nil
    c.flag [:l, :logger]

    c.desc 'Params file path. Inside should be hash of key values. These params override any defaults given in bricks.'
    c.default_value nil
    c.flag [:params, :paramfile]

    c.desc 'Remote system credentials file path. Inside should be hash of key values.'
    c.default_value nil
    c.flag [:credentials]

    c.desc 'Run on remote machine'
    c.switch [:r, :remote]

    c.desc 'Name of the deployed process'
    c.default_value nil
    c.flag [:n, :name]

    c.action do |global_options, options, _args|
      verbose = global_options[:verbose]
      options[:expanded_params] = if options[:params]
                                    # load params and credentials if given
                                    runtime_params = load_undot(options[:params])
                                    if options[:credentials]
                                      runtime_params = runtime_params.deep_merge(load_undot(options[:credentials]))
                                    end
                                    { 'config' => runtime_params }
                                  else
                                    { 'config' => {} }
                                  end

      # if there are some GDC_* params in config, put them on the level above
      gdc_params = options[:expanded_params]['config'].select { |k, _| k =~ /GDC_.*/ }
      options[:expanded_params].merge!(gdc_params)
      opts = options.merge(global_options).merge(:type => 'RUBY')
      GoodData.connect(opts)
      if options[:remote]
        fail 'You have to specify name of the deploy when deploying remotely' if options[:name].nil? || options[:name].empty?
        require_relative '../../commands/process'
        GoodData::Command::Process.run(options[:dir], './main.rb', opts)
      else
        require_relative '../../commands/runners'
        GoodData::Command::Runners.run_ruby_locally(options[:dir], opts)
      end
      puts HighLine.color('Running ruby brick - DONE', HighLine::GREEN) if verbose
    end
  end
end

# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'pathname'

base = Pathname(__FILE__).dirname.expand_path
Dir.glob(base + '*.rb').each do |file|
  blacklist = [
    File.join(base, 'rest_getters.rb'),
    File.join(base, 'rest_resource.rb')
  ]

  require file unless blacklist.include? file
end
require_relative 'rest_getters'
require_relative 'rest_resource'

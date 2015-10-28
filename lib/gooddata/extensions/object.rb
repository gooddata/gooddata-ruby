# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

class Object
  def blank?
    respond_to?(:empty?) ? empty? : !self
  end

  def duplicable?
    true
  end

  # Converts an object into a string suitable for use as a URL query string, using the given key as the param name.
  def to_query(key)
    "#{CGI.escape(key.to_param)}=#{CGI.escape(to_param.to_s)}"
  end

  def to_param
    to_s
  end
end

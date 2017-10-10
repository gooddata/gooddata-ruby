# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'concurrent'
require_relative '../core/thread_pool'

module Enumerable
  def pmap(&proc)
    return self unless proc

    results = map do |item|
      Concurrent::Promise.execute(executor: GoodData.thread_pool) { proc.call(item) }
    end

    job = Concurrent::Promise.zip(*results)
    job.wait!

    fail job.reason if job.rejected?

    results.map(&:value)
  end

  def peach(&proc)
    if proc
      promises = map do |item|
        Concurrent::Promise.execute(executor: GoodData.thread_pool) { proc.call(item) }
      end
      job = Concurrent::Promise.zip(*promises)
      job.wait!

      fail job.reason if job.rejected?
    end

    self
  end

  def flat_pmap(&proc)
    return self unless proc

    pmap(&proc).flatten(1)
  end

  def mapcat(initial = [], &block)
    reduce(initial) do |a, e|
      block.call(e).each do |x|
        a << x
      end
      a
    end
  end

  def pmapcat(initial = [], &block)
    intermediate = pmap(&block)
    intermediate.reduce(initial) do |a, e|
      e.each do |x|
        a << x
      end
      a
    end
  end

  def pselect(&block)
    intermediate = pmap(&block)
    zip(intermediate).select { |x| x[1] }.map(&:first)
  end

  def rjust(n, x)
    Array.new([0, n - length].max, x) + self
  end

  def ljust(n, x)
    dup.fill(x, length...n)
  end
end

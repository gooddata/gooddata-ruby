# encoding: UTF-8
require 'hashie'

require 'hashie/extensions/deep_merge'

class Hash
  include Hashie::Extensions::DeepMerge

  # Return a hash that includes everything but the given keys. This is useful for
  # limiting a set of parameters to everything but a few known toggles:
  #
  #   @person.update_attributes(params[:person].except(:admin))
  #
  # If the receiver responds to +convert_key+, the method is called on each of the
  # arguments. This allows +except+ to play nice with hashes with indifferent access
  # for instance:
  #
  #   {:a => 1}.with_indifferent_access.except(:a)  # => {}
  #   {:a => 1}.with_indifferent_access.except("a") # => {}
  #
  def except(*keys)
    dup.except!(*keys)
  end

  # Replaces the hash without the given keys.
  def except!(*keys)
    keys.each { |key| delete(key) }
    self
  end

  def undot
    # for each key-value config given
    hashes = map do |k, v|
      # dot notation to hash
      k.split('__').reverse.reduce(v) do |memo, obj|
        { obj => memo }.extend(Hashie::Extensions::DeepMerge)
      end
    end

    # merge back the keys as they came
    hashes.reduce do |memo, obj|
      memo.deep_merge(obj)
    end
  end
end

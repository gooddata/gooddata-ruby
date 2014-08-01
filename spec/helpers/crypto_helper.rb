require 'securerandom'

module CryptoHelper
  class << self
    def generate_password
      SecureRandom.hex(16)
    end
  end
end
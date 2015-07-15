# encoding: UTF-8

require_relative 'core/logging'

require_relative 'rest/rest'

module GoodData
  class << self
    DEFAULT_SSO_OPTIONS = {
      :url => '/gdc/app/account/bootstrap',
      :valid => 24 * 60 * 60
    }

    # Returns the active GoodData connection earlier initialized via GoodData.connect call
    #
    # @see GoodData.connect
    def connection
      # TODO: Remove this after successful rest-factory transition
      Rest::Client.connection # || fail('Please authenticate with GoodData.connect first')
    end

    alias_method :client, :connection

    # Connect to the GoodData API
    #
    # @param options
    # @param second_options
    # @param third_options
    #
    def connect(options = nil, second_options = nil, third_options = {})
      Rest::Client.connect(options, second_options, third_options)
    end

    # Disconnect (logout) if logged in
    def disconnect
      Rest::Client.disconnect
    end

    def with_connection(options = nil, second_options = nil, third_options = {}, &bl)
      connection = connect(options, second_options, third_options)
      bl.call(connection)
    rescue Exception => e # rubocop:disable RescueException
      puts e.message
      raise e
    ensure
      disconnect
    end

    def sso_url(login, provider, opts = DEFAULT_SSO_OPTIONS)
      opts = DEFAULT_SSO_OPTIONS.merge(opts)

      ts = DateTime.now.strftime('%s').to_i + opts[:valid]
      obj = {
        'email' => login,
        'validity' => ts
      }

      json_data = JSON.pretty_generate(obj) + "\n"

      file_json = Tempfile.new('gooddata-sso-json')
      file_json.write(json_data)

      file_json.rewind
      file_signed = Tempfile.new('gooddata-sso-signed')

      cmd = "gpg --no-tty --armor --yes -u #{login} --output #{file_signed.path} --sign #{file_json.path}"
      res = system(cmd)
      fail 'Unable to sign json' unless res

      file_signed.rewind
      file_final = Tempfile.new('gooddata-sso-final')

      cmd = "gpg --yes --no-tty --trust-model always --armor --output #{file_final.path} --encrypt --recipient security@gooddata.com #{file_signed.path}"
      res = system(cmd)
      fail 'Unable to encrypt json' unless res

      file_final.rewind
      final = file_final.read

      "#{GoodData::Helpers::AuthHelper.read_server}/gdc/account/customerlogin?sessionId=#{CGI.escape(final)}&serverURL=#{CGI.escape(provider)}&targetURL=#{CGI.escape(opts[:url])}"
    end

    def connect_sso(login, provider, opts = DEFAULT_SSO_OPTIONS)
      url = sso_url(login, provider, opts)
      res = RestClient.get url

      puts 'HEADERS: '
      puts res.headers

      puts 'COOKIES: '
      puts res.cookies

      obj = JSON.parse(res)
    end
  end
end

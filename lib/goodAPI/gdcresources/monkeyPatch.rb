ActiveResource::Connection.class_eval do
    def get_with_side_effects(path, headers = {})
      response = request(:get, path, build_request_headers(headers, :get))
      return [response, format.decode(response.body)]
    end
end

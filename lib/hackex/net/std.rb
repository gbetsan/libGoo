module HackEx
  module Network
    require 'net/http'
    require 'openssl'

    private
    def Get urip, params = {}
      auth_token = params.delete(:auth_token)
      Signature(params)
  
      uri = URI.join(HackEx::Request::URI_BASE, urip)
      uri.query = URI.encode_www_form(params)
      request = Net::HTTP::Get.new uri.request_uri
      request['Content-Type'] = 'application/x-www-form-urlencoded; charset=UTF-8'
      request['User-Agent'] = HackEx::Request::USER_AGENT
      request['X-API-KEY'] = auth_token unless auth_token.nil?
      request
    end

    def Post urip, params = {}
      auth_token = params.delete(:auth_token)
      Signature(params)
  
      uri = URI.join(HackEx::Request::URI_BASE, urip)
      request = Net::HTTP::Post.new uri.path
      request['Content-Type'] = 'application/x-www-form-urlencoded; charset=UTF-8'
      request['User-Agent'] = HackEx::Request::USER_AGENT
      request['X-API-KEY'] = auth_token unless auth_token.nil?
      request.body = URI.encode_www_form(params)
      request
    end

    public
    def Do http, request
      response = http.request request
      if response.is_a? Net::HTTPOK
        json = JSON.parse(response.body)
        raise HackExError, "Not success: #{json}" unless json['success']
        json
      else
        raise HackExError, "Not OK: #{response.inspect}, #{response.body}"
      end
    end

    def NetworkDo &proc
      uri_base = URI(HackEx::Request::URI_BASE)

      Net::HTTP.start(uri_base.host, uri_base.port, :use_ssl => true, :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
        proc.call(http)
      end
    end
  end
end

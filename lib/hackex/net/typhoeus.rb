module HackEx
  module Network
    require 'typhoeus'
    require 'uri'

    private
    def Get urip, params = {}
      auth_token = params.delete(:auth_token)
      Signature(params)
      uri = URI.join(HackEx::Request::URI_BASE, urip)
      Typhoeus::Request.new(
        uri.to_s,
        method: :get,
        params: params,
        headers: {
          'Accept' => '*/*',
          'Content-Type' => "application/x-www-form-urlencoded; charset=UTF-8",
          'User-Agent' => HackEx::Request::USER_AGENT,
          'X-API-KEY' => auth_token.to_s
        },
        ssl_verifypeer: false
      )
    end

    def Post urip, params = {}
      auth_token = params.delete(:auth_token)
      Signature(params)
      body = URI.encode_www_form(params)
      uri = URI.join(HackEx::Request::URI_BASE, urip)
      #uri = HackEx::Request::URI_BASE.to_s + urip.to_s
      Typhoeus::Request.new(
        uri.to_s,
        method: :post,
        body: body,
        headers: {
          'Content-Type' => "application/x-www-form-urlencoded; charset=UTF-8",
          'User-Agent' => HackEx::Request::USER_AGENT,
          'X-API-KEY' => auth_token.to_s
        },
        ssl_verifypeer: false
      )
    end

    public
    def Do http, request
      array = true
      unless request.is_a? Array
        array = false
        request = [request]
      end

      request.each do |r|
        http.queue r
      end
      http.run
      out = []
      suc = true
      request.each do |r|
        response = r.response
        #puts response.code
        if response.code == 200
          json = JSON.parse(response.body)
          out << json
          unless array
            raise HackExError, "Not success: #{json}" unless json['success']
          end
          #json
        else
          raise HackExError, "Not OK: #{response.inspect}, #{response.body}" unless array
        end
      end
      if array
        out
      else
        out[0]
      end
    end

    def NetworkDo &proc
      http = Typhoeus::Hydra.hydra # single
      #puts http.inspect
      #puts "Use Hydra"
      proc.call(http)
    end
  end
end

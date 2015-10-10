module LibGoo
  class Processes #Much needed such wow
    attr_reader :id, :params

    def initialize(params)
      if params.is_a?(Hash) || params.is_a?(JSON)
        raise LibGooError, 'No specified key \'id\' in arguments'  unless params.has_key?('id')
        @id, @params = params['id'], params
      elsif params.is_a?(Fixnum)
        @id = params
      else
        raise LibGooError, 'Unavailable type ' + params.class.to_s
      end
    end
  end
end
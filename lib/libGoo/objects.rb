module LibGoo
  class ObjectProcessor #Much needed such wow, really, idk why it's here
    attr_reader :id, :params

    def initialize(params, raise_if)
      if params.is_a?(Hash) || params.is_a?(JSON)
        raise LibGooError, "No specified key #{raise_if} in params"  unless params.has_key?(raise_if) && raise_if
        @params = params
        #params.each_pair do |k,v|
        #  instance_variable_set '@'+k.to_s,v
        #end
      elsif params.is_a?(Fixnum)
        @id = params
      else
        raise LibGooError, "Unavailable type of argument: #{params.class.to_i}."
      end
    end

    def method_missing(m, *args)
      if @params.has_key?(m.to_s)
        @params[m.to_s]
      elsif @params.has_key?(m)
        @params[m]
      else
        super
      end
    end
  end

  class Victim < ObjectProcessor
    def initialize(params)
      super(params, 'user_id')
    end
  end
end

require 'pp'
include LibGoo
#u = ObjectProcessor.new(vasya: 1, tolya: 3, lolik: 2)
#pp u.lolik
us = Victim.new(lol: 1, 'user_id' => 1001)
puts us.lol
puts us.user_id
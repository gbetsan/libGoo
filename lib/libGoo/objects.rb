module LibGoo
  class ObjectProcessor #Much needed such wow, really, idk why it's here
    attr_reader :params

    def initialize(params, raise_if)
      if params.is_a?(Hash) || params.is_a?(JSON)
        @raise_if = raise_if
        raise LibGooError, "No specified key #{raise_if} in params"  unless params.has_key?(raise_if) && raise_if
        @params = params
      else
        raise LibGooError, "Unavailable type of argument: #{params.class.to_s}."
      end
    end

    def method_missing(m, *args)
      var = self.get_var(m)
      return var if var
      super
    end

    def get_var(m)
      if @params.has_key?(m.to_s)
        @params[m.to_s]
      elsif @params.has_key?(m)
        @params[m]
      else
        false
      end
    end

    def self.descendants
      ObjectSpace.each_object(Class).select { |klass| klass < self }
    end

  end

  class Victim < ObjectProcessor
    def initialize(params)
      @raise_if = 'user_id'
      super(params, @raise_if)
    end

  end

  class Processes < ObjectProcessor
    def initialize(params)
      @raise_if = 'id'
      super(params, @raise_if)
    end
  end
end

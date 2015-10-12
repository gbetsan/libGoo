module LibGoo
  class ObjectProcessor #Much needed such wow, really, idk why it's here
    attr_reader :params

    def initialize(params, raise_if)
      if params.is_a?(Hash) || params.is_a?(JSON)
        raise LibGooError, "No specified key #{raise_if} in params"  unless params.has_key?(raise_if) && raise_if
        @params = params
      else
        raise LibGooError, "Unavailable type of argument: #{params.class.to_s}."
      end
    end

    def method_missing(m, *args)
      return self.get_var(m) if self.get_var(m)
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

    def self.parent
      LibGoo::ObjectProcessor
    end
  end

  class Victim < ObjectProcessor
    @@important = 'user_id'
    def initialize(params)
      super(params, @@important)
    end

  end

  class Processes < ObjectProcessor
    @@important = 'id'
    def initialize(params)
      super(params, @@important)
    end
  end
end

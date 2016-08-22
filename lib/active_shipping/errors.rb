module ActiveShipping
  class Error < StandardError
  end

  class RequestError < ActiveShipping::Error
  end

  class ResponseError < ActiveShipping::Error
    attr_reader :response

    def initialize(response = nil)
      if response.is_a? Response
        super(response.message)
        @response = response
      else
        super(response)
      end
    end
  end

  class ResponseContentError < ActiveShipping::Error
    def initialize(exception, content_body = nil)
      super([exception.message, content_body].compact.join(" \n\n"))
    end
  end

  class ShipmentNotFound < ActiveShipping::Error
  end

  class USPSValidationError < RequestError
  end

  class USPSMissingRequiredTagError < RequestError
    def initialize(tag, prop)
      super("Missing required tag #{tag} set by property #{prop}")
    end
  end
end

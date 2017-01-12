module ActiveShipping #:nodoc:
  class Package
    cattr_accessor :default_options do {} end
    attr_reader :weight, :length, :width, :height, :options, :value, :currency

    alias_attribute :mass, :weight

    def initialize(weight:, length:, width:, height: nil, options: {})
      @options = @@default_options.merge(options.symbolize_keys)

      raise ArgumentError, "Weight needs to be a Measured::Measurable object" unless weight.is_a?(Measured::Measurable)
      raise ArgumentError, "Length needs to be a Measured::Measurable object" unless length.is_a?(Measured::Measurable)
      raise ArgumentError, "Width needs to be a Measured::Measurable object" unless width.is_a?(Measured::Measurable)
      raise ArgumentError, "Height needs to be a Measured::Measurable object" unless height.nil? || length.is_a?(Measured::Measurable)

      @weight = weight

      @length = length
      @width  = width
      @height = height || ( cylinder? ? width : Measured::Length.new(0, length.unit) )

      @value = self.class.cents_from(options[:value])
      @currency = options[:currency] || options[:value].try(:currency)
    end

    def dimensions
      [@length, @width, @height]
    end

    def girth
      @girth ||= cylinder ? width.scale(Math::PI) : (width + height).scale(2)
    end
    alias_method :circumference, :girth
    alias_method :around, :girth

    def volume
      @volume ||= if cylinder?
        Math::PI * width.scale(0.5).value * height.scale(0.5).value * length.value
      else
        length.value * width.value * height.value
      end
    end

    def cylinder?
      @cylinder ||= @options[:cylinder].present?
    end
    alias_method :tube?, :cylinder?

    def gift?
      @gift ||= @options[:gift].present?
    end

    def oversized?
      @oversized ||= @options[:oversized].present?
    end

    def unpackaged?
      @unpackaged ||= @options[:unpackaged].present?
    end

    def self.cents_from(money)
      return nil if money.nil?
      if money.respond_to?(:cents)
        return money.cents
      else
        case money
        when Float
          (money * 100).round
        when String
          money =~ /\./ ? (money.to_f * 100).round : money.to_i
        else
          money.to_i
        end
      end
    end
  end
end

# ShipmentOption is the abstract base class for all supported shipment options per carrier.
#
# To implement support for a carrier's shipment option(s), you should subclass this class
# with the following class variables:
#
# @@carrier_name [String]
#
# Name of the carrier that implements the shipment options
# e.g.
# @@carrier_name = 'usps'
#
#
#
# @@all_options_details [Hash]
#
# Mapping of an @code to its details, such as name, description, and/or options_params
# @@all_options_details = {
#   'signature_required' => {
#     name: 'Signature Required',
#     description: 'A signature is required on delivery.',
#     option_params: [:value, :fragile]
#   }
# }

module ActiveShipping
  class ShipmentOption
    class CodeNotFoundError < StandardError ; end

    cattr_reader :carrier_name, :all_options_details
    attr_reader :code, :option_args, :name, :description

    # @code [String]
    #
    # @options_details should contain the code as a top-level key
    # e.g. code: 'signature_required'
    #
    #
    #
    # @option_args [Hash] (Optional)
    #
    # Contain additional arguments necessary for initialized shipment option
    # e.g. option_args: { value: 23.50, fragile: true }
    def initialize(args = {})
      @code = args.fetch(:code)
      raise CodeNotFoundError, "#{self.class.carrier_name} does not support this shipment option code." unless option_details

      @option_args = args[:option_args] || {}
      @option_args.select! { |key, _| option_details[:option_params].include? key }

      @name = option_details[:name] || ''
      @description = option_details[:description] || ''
    end

    private

    def option_details
      @option_details ||= self.class.all_options_details[@code]
    end
  end
end

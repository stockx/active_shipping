require 'test_helper'

class ShipmentOptionTest < Minitest::Test
  class ExampleShipmentOption < ActiveShipping::ShipmentOption
    @@carrier_name = 'example_carrier'.freeze
    @@all_options_details = {
      'example_code' => {
        name: 'Example Code',
        description: 'Some example shipment option.',
        option_params: [:foo, :bar]
      }
    }.freeze
  end

  def setup
    @shipment_option = ExampleShipmentOption.new(
      code: 'example_code',
      option_args: { foo: 'hello', bar: 'world' }
    )
  end

  def test_code_not_found_error
    assert_raises ShipmentOption::CodeNotFoundError do
      invalid_option = ExampleShipmentOption.new(code: 'bad_code')
    end
  end

  def test_name
    assert_equal 'Example Code', @shipment_option.name
  end

  def test_description
    assert_equal 'Some example shipment option.', @shipment_option.description
  end

  def test_option_args
    assert_equal({ foo: 'hello', bar: 'world' }, @shipment_option.option_args)
  end

  def test_option_args_filtered
    filtered_option = ExampleShipmentOption.new(
      code: 'example_code',
      option_args: { foo: 'hello', bar: 'world', baz: 'bad arg' }
    )

    assert_equal({ foo: 'hello', bar: 'world' }, filtered_option.option_args)
  end

  def test_empty_option_args
    empty_args_option = ExampleShipmentOption.new(code: 'example_code')

    assert_equal({}, empty_args_option.option_args)
  end
end

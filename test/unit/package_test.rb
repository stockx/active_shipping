require 'test_helper'

class PackageTest < ActiveSupport::TestCase
  setup do
    @weight = Measured::Weight(500, :grams)
    @length = Measured::Length(30, :cm)
    @width = Measured::Length(25, :cm)
    @height = Measured::Length(15, :cm)

    @value = 1299
    @currency = "USD"

    @options = {
      value: @value,
      currency:  @currency,
    }

    @default_args = { weight: @weight, length: @length, width: @width, height: @height, options: @options }
    @default_package = Package.new(**@default_args)
  end

  test "#initialize package from mass" do
    ten_pounds = Measured::Weight.new(10, :pounds)
    package = Package.new(**@default_args.merge(weight: ten_pounds))
    assert_equal ten_pounds, package.weight
  end

  test "#initialize with no options defaults them all to false" do
    package = Package.new(**@default_args.merge(options: {}))
    refute_predicate package, :cylinder?
    refute_predicate package, :tube?
  end

  test "#initialize defaults value and currency to nil if not passed" do
    package = Package.new(**@default_args.merge(options: {}))
    assert_nil package.value
    assert_nil package.currency
  end

  test "#initialize default shape to box" do
    assert_predicate @default_package, :box?
    refute_predicate @default_package, :tube?
    refute_predicate @default_package, :envelope?
  end

  test "#initialize sets shape for tube" do
    package = Package.new(**@default_args.merge(options: { shape: 'tube' }))
    assert_predicate package, :tube?
    assert_predicate package, :cylinder?
    refute_predicate package, :box?
    refute_predicate package, :envelope?
  end

  test "#initialize sets shape for envelope" do
    package = Package.new(**@default_args.merge(options: { shape: 'envelope' }))
    refute_predicate package, :tube?
    refute_predicate package, :box?
    assert_predicate package, :envelope?
  end

  test "#initialize with String value" do
    @options[:value] = "10.00"
    package = Package.new(**@default_args.merge(options: @options))
    assert_equal 1000, package.value
  end

  test "#initialize with Float value" do
    @options[:value] = 12.34
    package = Package.new(**@default_args.merge(options: @options))
    assert_equal 1234, package.value
  end

  # not great, should be fixed - all other inputs expect dollars, and this assumes Integers are cents
  test "#initialize with Integer value" do
    @options[:value] = 10
    package = Package.new(**@default_args.merge(options: @options))
    assert_equal 10, package.value
  end

  test "#initialize with value object that responds to cents" do
    money_mock = mock()
    money_mock.stubs(:cents).returns(321)
    @options[:value] = money_mock
    package = Package.new(**@default_args.merge(options: @options))
    assert_equal 321, package.value
  end

  test "#initialize raises ArgumentError if weight is omitted" do
    assert_raises ArgumentError do
      package = Package.new(**@default_args.except(:weight))
    end
  end

  test "#initialize raises ArgumentError if length is omitted" do
    assert_raises ArgumentError do
      package = Package.new(**@default_args.except(:length))
    end
  end

  test "#initialize raises ArgumentError if width is omitted" do
    assert_raises ArgumentError do
      package = Package.new(**@default_args.except(:width))
    end
  end

  test "#initialize sets height to zero if omitted and non-tube" do
    package = Package.new(**@default_args.except(:height))

    assert_equal Measured::Length(0, :cm), package.height
  end

  test "#initialize sets height to width if omitted and tube" do
    @options[:shape] = :tube
    package = Package.new(**@default_args.merge(options: @options).except(:height))

    assert_equal package.width, package.height
  end

  test "#dimensions returns an array of the dimensions" do
    assert_equal [@length, @width, @height], @default_package.dimensions
  end

  test "#girth returns the circumference of the surface perpendicular to length for non-cylindrical package" do
    skip "Requires Measured 2.0"
    square_girth = (@width + @height).scale(2)
    assert_equal square_girth, @default_package.girth
  end

  test "#girth returns the circumference of the surface perpendicular to length for cylindrical package" do
    skip "Requires Measured 2.0"
    @options[:shape] = 'tube'
    package = Package.new(**@default_args.merge(options: @options))

    circumference = @width.scale(Math::PI)
    assert_equal circumference, @default_package.girth
  end

  # This should return a Measured::Volume, but that doesn't exist yet.
  # So we'll return a raw value like we have in the past until that is a thing.
  test "#volume returns the box volume for non-cylindrical package" do
    box_volume = @length.value * @width.value * @height.value
    assert_equal box_volume, @default_package.volume
  end

  # This should return a Measured::Volume, but that doesn't exist yet.
  # So we'll return a raw value like we have in the past until that is a thing.
  test "#volume returns the volume for cylindrical package" do
    skip "Requires Measured 2.0"
    @options[:shape] = 'tube'
    package = Package.new(**@default_args.merge(options: @options))

    circumference = @width.scale(Math::PI)
    tube_volume = Math::PI * @length.value * @width.value * 0.25 * @height.value
    assert_equal tube_volume, @default_package.volume
  end
end

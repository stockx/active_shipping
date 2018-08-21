module ActiveShipping
    class IPARCEL < Carrier

        cattr_accessor :default_options
        cattr_reader :name
        @@name = "IPARCEL"
  
    def shipment_cost(shipping_event)
      if shipping_event.nil?
        raise StandardError.new("I-Parcel create shipment call not working. CreateShipment response nil.")
      end
      shipping_event["ServiceLevels"][0][0]["subtotalCompanyCurrency"]
    end

    def first_name(full_name)
        full_name.split(" ")[0]
    end
    
    def last_name(full_name)
        full_name.split(" ")[1]
    end
  
    def shipping_label(shipping_event)
      body = {
      Key: @options[:key],
      TrackingNumber: shipping_event["CarrierTrackingNumber"],
      FileType: "GIF",
      DirectShipping: false}.to_json
  
      res = make_post_req("GetLabel", body)
      return res.body
    end
  
    def track(tracking_number)
      require 'uri'
      require 'net/http'
      require 'json'
  
      url = URI("https://webservices.i-parcel.com/api/Track?key=" + @options[:key] + "&trackingNumbers=" + "#{tracking_number}")
      begin
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true
        request = Net::HTTP::Get.new(url)
        response = http.request(request)
  
        tracking_info = JSON.parse(response.body)
        events = tracking_info["Parcels"][0]["Events"]
  
        events.each do |event|
          if event["EventCodeDesc"] == "Delivered"
            return {
              "status": "Delivered",
              "delivery_date": event["EventDate"]
            }
          end
        end
  
        events.each do |event|
          if event["EventCodeDesc"] == "In transit"
            return {
              "status": "In Transit",
              "delivery_date": nil
            }
          end
        end
  
        return nil
      rescue => e
          puts "failed #{e}"
      end
    end
  
    def build_shipment_request_payload(origin, destination, pckgs)
      {
        Key: @options[:key],
        ItemDetailsList: [
          {
            SKU: pckgs[0].options[:uuid],
            CustWeightLbs: @data.data[:packages][0][:weight][:value],
            CustLengthInches: 14,
            CustWidthInches: 10,
            CustHeightInches: 4,
            HTSCode: pckgs[0].options[:commodity_code],
            CountryOfOrigin: @data.country_of_origin,
            Quantity: 1,
            OriginalPrice: pckgs[0].options[:value],
            ProductDescription: pckgs[0].options[:name],
            ValueCompanyCurrency: pckgs[0].options[:value],
            ValueShopperCurrency: pckgs[0].options[:value]
          },
        ],
        AddressInfo: {
          Shipping: {
            FirstName: first_name(destination[:name]),
            LastName: last_name(destination[:name]),
            Street1: destination[:address1],
            Street2: destination[:address2],
            PostCode: destination[:postal_code],
            City: destination[:city],
            CountryCode: destination[:country],
            Email: destination[:email],
            Phone: destination[:phone],
          },
          Billing: {
            FirstName: nil,
            LastName: nil,
            Street1: nil,
            Street2: nil,
            PostCode: nil,
            City: nil,
            CountryCode: nil,
            Email: nil,
            Phone: nil,
          },
        },
      }.to_json
    end
  
    def create_shipment(origin, destination, pckgs, data)
      @data = data
      shipment_request_payload = build_shipment_request_payload(origin, destination, pckgs)
  
      res = make_post_req("SubmitParcel", shipment_request_payload)
      return JSON.parse(res.body)
    end
  
    def make_post_req(endpoint, body) 
      require 'net/http'
      require 'json'
      url = "https://webservices.i-parcel.com/api/" + "#{endpoint}"
      begin
          uri = URI(url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          req = Net::HTTP::Post.new(uri.path, {'Content-Type' =>'application/json'})
          req.body = body
          res = http.request(req)
          return res
      rescue => e
          puts "failed #{e}"
      end
    end
end
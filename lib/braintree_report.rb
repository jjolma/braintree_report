require 'uri'
require 'net/https'
require 'rubygems'
require 'xmlsimple'

#
# Basic class for Braintree's reporting API
#
# It has no real API yet, just returns a hash of Braintree's query results
#
# Note: very rough prototype.  Started down the ActiveResource route but ran into a bunch of problems:
# * Braintree doesn't add "type='array'" to arrays
# * ActiveResource's Hash.from_xml strips out the id attribute
#   Braintree uses to specify merchant defined fields.  So, we
#   couldn't see what the fifth merchant defined field is, for example
# * Braintree doesn't wrap collections properly. For example, instead
#   of somethign like "<foos><foo></foo><foo></foo></foos" they use
#   "<foo></foo><foo></foo>"
#
class BraintreeReport
  BASE_URL = "https://secure.braintreepaymentgateway.com/api/query.php"

  class << self
    def query(options={})
      query = options.map { |k,v| "#{k}=#{v}" }.join('&')
      full_url = [BASE_URL, query].join '?'

      uri = URI.parse(full_url)
      server = Net::HTTP.new uri.host, uri.port
      server.use_ssl = uri.scheme == 'https'
      server.verify_mode = OpenSSL::SSL::VERIFY_NONE
      response = server.post BASE_URL, query

      response_hash = XmlSimple.xml_in(response.body, { 'NormaliseSpace' => 2 })

      massage(response_hash)
    end

    # helper for extracting merchant defined fields
    # { 'index' => 'value' }
    def merchant_defined_fields(response)
      if response['transaction']
        mdfs = response['transaction']['merchant_defined_field']
        if mdfs
          mdfs = [mdfs] if mdfs.is_a? Hash
          mdfs.inject({}) do |memo, kv|
            k,v = kv['id'], kv['content']
            memo[k] = v
            memo
          end
        end
      end
    end


    # stolen and trimmed from rails' Hash.from_xml
    def massage(value)
      case value.class.to_s
      when 'Hash'
        if value.size == 0
          nil
        else
          xml_value = value.inject({}) do |h,(k,v)|
            h[k] = massage(v)
            h
          end
        end
      when 'Array'
        value.map! { |i| massage(i) }
        case value.length
        when 0 then nil
        when 1 then value.first
        else value
        end
      when 'String'
        value
      else
        raise "can't massage #{value.class.name} - #{value.inspect}"
      end
    end
  end
end

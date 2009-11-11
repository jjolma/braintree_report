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

      XmlSimple.xml_in(response.body, { 'NormaliseSpace' => 2 })
    end

    # helper for extracting merchant defined fields
    # { 'index' => 'value' }
    def merchant_defined_fields(response)
      if response['transaction']
        mdfs_hash = response['transaction'][0]['merchant_defined_field']
        if mdfs_hash
          mdfs = mdfs_hash.inject({}) do |memo, kv|
            k,v = kv['id'], kv['content']
            memo[k] = v
            memo
          end
        end
      end
    end
  end

end

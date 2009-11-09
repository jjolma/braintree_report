require 'active_resource'

#
# ActiveResource class for Braintree's reporting API
#
class BraintreeReport < ActiveResource::Base
  self.site = "https://secure.braintreepaymentgateway.com/api/query.php"

  class << self
    # Massage Braintree's data into something suitable for
    # ActiveResource. They don't supply the type attribute for
    # collections and they don't properly wrap collections
    def instantiate_collection(collection, prefix_options = {})
      if collection.kind_of? Array
        collection.collect! { |record| instantiate_record(record, prefix_options) }
      elsif collection.is_a?(Hash) && collection.values.size == 1
        [instantiate_record(collection, prefix_options)]
      elsif collection.is_a?(String) && collection.blank?
        []
      end
    end

    alias :resource_find :find

    # NOTE: using from gives the correct endpoing url, but it works without it
    # t = Braintree::Query.find(:first, :from => '/api/query.php', :params => { ... }
    def find(*arguments)
      output = resource_find(*arguments)
      handle_any_errors(output)
      output = output.transaction if output && output.respond_to?(:transaction)
      output
    end

    def handle_any_errors(output)
      if error = (output.respond_to?(:error_response) && output.error_response)
        if error =~ Regexp.new("Invalid Username/Password")
          raise ActiveResource::UnauthorizedAccess.new(error)
        end
      end
    end
  end
end

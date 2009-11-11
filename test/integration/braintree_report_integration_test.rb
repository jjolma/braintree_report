$:.unshift(File.dirname(__FILE__) + '/../../lib')
require File.dirname(__FILE__) + '/../test_helper'
require 'mocha'
require 'active_resource'
require 'braintree_report'

class BraintreeReportIntegrationTest < ActiveSupport::TestCase

  test "real query with single transaction" do
    response = BraintreeReport.query :order_id => 'jpj_order_1257878623', :username => 'testapi', :password => 'password1'
    mdfs = BraintreeReport.merchant_defined_fields(response)
    assert_equal '3', mdfs['1']
    assert_equal 'hi4_subtype', mdfs['4']
    assert_equal 'hi5_promo_code', mdfs['5']
  end

  test "real query with bad auth" do
    h = BraintreeReport.query :order_id => 'jpj_order_1257878623', :username => 'testapi', :password => 'OOPS'
    assert_match /Invalid Username\/Password/, h['error_response']
  end
end

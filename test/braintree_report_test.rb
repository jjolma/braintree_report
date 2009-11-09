$:.unshift(File.dirname(__FILE__) + '/../lib')
require File.dirname(__FILE__) + '/test_helper'
require 'mocha'
require 'active_resource'
require 'braintree_report'

class BraintreeReportTest < ActiveSupport::TestCase

  def setup
    ActiveSupport::XmlMini.backend = "LibXML"
    FakeWeb.allow_net_connect = false
  end

   test "raises unauthorized access if invalid username/password response" do
     FakeWeb.register_uri(:get,
                          "https://secure.braintreepaymentgateway.com/api/query.php/braintree_reports.xml",
                          :body => invalid_credentials_response)

     assert_raises ActiveResource::UnauthorizedAccess do
       report = BraintreeReport.find(:first, 'testapi', :params => { :password => 'password1', :order_id => '123'})
     end
   end

  test "empty results" do
    FakeWeb.register_uri(:get,
                         "https://secure.braintreepaymentgateway.com/api/query.php/braintree_reports.xml",
                         :body => empty_response)
    assert_nil BraintreeReport.find(:first, 'testapi', :params => { :password => 'password1', :order_id => '123'})
    assert_equal [], BraintreeReport.find(:all, 'testapi', :params => { :password => 'password1', :order_id => '123'})
  end

  test "find first" do
    FakeWeb.register_uri(:get,
                         "https://secure.braintreepaymentgateway.com/api/query.php/braintree_reports.xml",
                         :body => single_response)
    report = BraintreeReport.find(:first, 'testapi', :params => { :password => 'password1', :order_id => '123'})
    assert report.is_a? BraintreeReport::Transaction
    assert_equal '123', report.transaction_id
  end

  # TODO support for find all
  #    test "find all" do
  #      FakeWeb.register_uri(:get,
  #                           "https://secure.braintreepaymentgateway.com/api/query.php/braintree_reports.xml",
  #                           :body => multiple_response)
  #      report = BraintreeReport.find(:all, 'testapi', :params => { :password => 'password1', :order_id => '123'})
  #      assert report.is_a? Array
  #      assert_equal 2, report.size
  #      assert_equal '123', report.first.transaction_id
  #    end

  protected
  def invalid_credentials_response
    <<-EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <nm_response>
      <error_response>Invalid Username/Password REFID:200402058</error_response>
    </nm_response>
    EOS
  end

  def empty_response
    <<-EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <nm_response>
    </nm_response>
    EOS
  end

  def single_response
    <<-EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <nm_response>
	<transaction>
		<transaction_id>123</transaction_id>
		<platform_id></platform_id>
		<transaction_type>cc</transaction_type>
		<cc_bin>411111</cc_bin>
		<action>
			<amount>10.00</amount>
			<action_type>sale</action_type>
		</action>
	</transaction>
    </nm_response>
    EOS
  end

  def multiple_response
    <<-EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <nm_response>
      <transaction>
        <transaction_id>123</transaction_id>
        <platform_id></platform_id>
        <transaction_type>cc</transaction_type>
        <condition>pending</condition>
      </transaction>
      <transaction>
        <transaction_id>456</transaction_id>
        <platform_id></platform_id>
        <transaction_type>cc</transaction_type>
        <condition>pending</condition>
      </transaction>
    </nm_response>
    EOS
  end

end

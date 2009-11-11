$:.unshift(File.dirname(__FILE__) + '/../lib')
require File.dirname(__FILE__) + '/test_helper'
require 'mocha'
require 'active_resource'
require 'braintree_report'

class BraintreeReportTest < ActiveSupport::TestCase

  def setup
    FakeWeb.allow_net_connect = false
  end

   test "raises unauthorized access if invalid username/password response" do
     FakeWeb.register_uri(:post,
                          "https://secure.braintreepaymentgateway.com/api/query.php",
                          :body => invalid_credentials_response)

    report = BraintreeReport.query(:password => 'password1', :order_id => '123')
    assert_match /Invalid Username\/Password/, report['error_response']
   end

  test "empty results" do
    FakeWeb.register_uri(:post,
                         "https://secure.braintreepaymentgateway.com/api/query.php",
                         :body => empty_response)
    report = BraintreeReport.query(:password => 'password1', :order_id => '123')

    # ideally:
    #     assert_nil
    #     assert_equal [], BraintreeReport.find(:all, 'testapi', :params => { :password => 'password1', :order_id => '123'})

    # for now:
    assert_nil report
  end

  test "find first" do
    FakeWeb.register_uri(:post,
                         "https://secure.braintreepaymentgateway.com/api/query.php",
                         :body => single_response)
    report = BraintreeReport.query(:password => 'password1', :order_id => '123')

    # ideally:
    # assert report.is_a? BraintreeReport::Transaction

    assert_equal '123', report['transaction']['transaction_id']
  end

  test "retains indexes of merchant defined fields" do
    FakeWeb.register_uri(:post,
                         "https://secure.braintreepaymentgateway.com/api/query.php",
                         :body => single_response_with_custom_fields)
    report = BraintreeReport.query(:password => 'password1', :order_id => '123')

    # ideally:
    # assert report.is_a? BraintreeReport::Transaction
    #     assert report.merchant_defined_field.is_a? Array
    #     assert_equal 'custom_0', report.merchant_defined_field[0]
    #     assert_nil report.merchant_defined_field[1]
    #     assert_equal 'custom_2', report.merchant_defined_field[2]
    #     assert_equal 'custom_3', report.merchant_defined_field[3]

    # for now:
    mdfs = BraintreeReport.merchant_defined_fields(report)
    assert_equal 'custom_0', mdfs['1']
    assert_equal 'custom_2', mdfs['3']
    assert_equal 'custom_3', mdfs['4']
  end

  test "retains index of single merchant defined field" do
    FakeWeb.register_uri(:post,
                         "https://secure.braintreepaymentgateway.com/api/query.php",
                         :body => single_response_with_single_custom_field)
    report = BraintreeReport.query(:password => 'password1', :order_id => '123')

    mdfs = BraintreeReport.merchant_defined_fields(report)
    assert_equal 'custom_2', mdfs['3']
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

  def single_response_with_custom_fields
    <<-EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <nm_response>
	<transaction>
		<transaction_id>123</transaction_id>
 		<merchant_defined_field id="1">custom_0</merchant_defined_field>
        <merchant_defined_field id="3">custom_2</merchant_defined_field>
        <merchant_defined_field id="4">custom_3</merchant_defined_field>
	</transaction>
    </nm_response>
    EOS
  end

  def single_response_with_single_custom_field
    <<-EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <nm_response>
	<transaction>
		<transaction_id>123</transaction_id>
        <merchant_defined_field id="3">custom_2</merchant_defined_field>
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

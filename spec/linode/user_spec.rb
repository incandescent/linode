require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require 'linode'

describe Linode::User do
  before :each do
    @api_key = 'foo'
    @linode = Linode::User.new(:api_key => @api_key)
  end
  
  it 'should be a Linode instance' do
    @linode.class.should < Linode
  end
  
  it 'should be able to return the API key for the connection' do
    @linode.should respond_to(:getapikey)
  end
  
    describe "when accessing the #{action} API" do
      it 'should allow a data hash' do
        lambda { @linode.send(action.to_sym, {}) }.should_not raise_error(ArgumentError)
      end
    
      it 'should not require arguments' do
        lambda { @linode.send(action.to_sym) }.should_not raise_error(ArgumentError)      
      end
    
      it "should request the user.#{action} action" do
        @linode.expects(:send_unauthenticated_request).with {|api_action, data| api_action == "user.#{action}" }
        @linode.send(action.to_sym)
      end
    
      it 'should provide the data hash when making its request' do
        @linode.expects(:send_unauthenticated_request).with {|api_action, data| data = { :foo => :bar } }
        @linode.send(action.to_sym, {:foo => :bar})
      end
    
      it 'should return the result of the request' do
        @linode.expects(:send_unauthenticated_request).returns(:bar => :baz)      
        @linode.send(action.to_sym).should == { :bar => :baz }      
      end
    end
  describe 'when returning the API key for the connection' do
    it 'should work without arguments' do
      lambda { @linode.getapikey }.should_not raise_error(ArgumentError)
    end
    
    it 'should not allow arguments' do
      lambda { @linode.getapikey(:foo) }.should raise_error(ArgumentError)      
    end
    
    it 'should return the api_key via the Linode handle' do
      @linode.stubs(:api_key).returns('foo')
      @linode.getapikey.should == 'foo'
    end
  end
end

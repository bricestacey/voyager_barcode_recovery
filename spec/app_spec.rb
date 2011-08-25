require 'spec_helper'

describe Barcode do
  describe "GET /", :type => :request do 
    it "GET /" do
      get '/'

      last_response.should be_ok
    end
  end

  describe "POST /", :type => :request do
    before(:each) do
      @patron = Factory.build(:patron)
      Barcode::Patron.stub(:find_by_ums) {@patron}
    end
    it "should send an email to the patron" do
      Pony.should_receive(:mail).once

      post '/', :pid => '12345678'
    end
  end
end

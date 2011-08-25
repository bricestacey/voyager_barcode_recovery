require 'spec_helper'

describe Barcode do
  describe "GET /", :type => :request do 
    it "GET /" do
      get '/'

      last_response.should be_ok
    end
  end

  describe "POST /", :type => :request do
    context "a valid UMS number is posted" do
      before(:each) do
        @patron = Factory.build(:patron)
        Barcode::Patron.stub(:find_by_ums) {@patron}
      end

      it "should send an email to the patron" do
        Pony.should_receive(:mail).once

        post '/', :pid => '12345678'
      end

      it "should set a success message" do
        post '/', :pid => '12345678'

        last_response.body.should include "An email is on the way!"
      end
    end

    context "an invalid UMS number is posted" do
      before(:each) do
        Barcode::Patron.stub(:find_by_ums) {nil}
      end

      it "should not send an email" do
        Pony.should_receive(:mail).never

        post '/', :pid => '12345678'
      end

      it "should set an error message" do
        post '/', :pid => '12345678'

        last_response.body.should include "We couldn't find your UMS number in our system."
      end
    end
  end
end

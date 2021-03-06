require 'sinatra/base'
require 'erb'
require 'oci8'
require 'pony'
require 'active_model'

class Barcode < Sinatra::Base
  CONFIG = YAML.load_file(File.join(File.dirname(__FILE__), "config.yml"))

  class Patron
    include ActiveModel::Validations

    validates :first_name, :last_name, :barcode, :patron_group, :email, :presence => true
    attr_accessor :first_name, :last_name, :barcode, :patron_group, :email

    def initialize(attributes = {})
      attributes.each do |name, value|
        send("#{name}=", value)
      end
    end

    def self.find_by_ums(id)
      sql =<<-SQL
        SELECT
          PATRON.FIRST_NAME,
          PATRON.LAST_NAME,
          PATRON_BARCODE.PATRON_BARCODE,
          PATRON_GROUP.PATRON_GROUP_DISPLAY as PATRON_GROUP,
          PATRON_ADDRESS.ADDRESS_LINE1 as EMAIL
        FROM
          PATRON
          LEFT JOIN PATRON_BARCODE USING(PATRON_ID)
          LEFT JOIN PATRON_GROUP USING(PATRON_GROUP_ID)
          LEFT JOIN (SELECT ADDRESS_LINE1, PATRON_ID FROM PATRON_ADDRESS WHERE ADDRESS_TYPE = 3) PATRON_ADDRESS USING(PATRON_ID)
        WHERE
          PATRON_BARCODE.BARCODE_STATUS = 1 AND
          PATRON_BARCODE.PATRON_BARCODE is not null AND
          (UPPER(PATRON.INSTITUTION_ID) = :ident OR
           UPPER(PATRON_ADDRESS.ADDRESS_LINE1) = :ident OR
           UPPER(PATRON.SSAN) = :ident)
      SQL

      begin 
        r = OCI8.new(CONFIG['oracle']['username'], CONFIG['oracle']['password']).exec(sql, id).fetch

        return r.nil? ? nil : Patron.new(:first_name => r[0], :last_name => r[1], :barcode => r[2], :patron_group => r[3], :email => r[4])
      rescue => e
        # log error here
        return nil
      end
    end
  end

  helpers do
    def mail_barcode_reminder(patron)
      Pony.mail(
        :to          => patron.email,
        :from        => CONFIG['email']['from'],
        :subject     => CONFIG['email']['subject'],
        :body        => erb(:email, :locals => { :patron => self }),
        :via         => CONFIG['email']['via'],
        :via_options => CONFIG['email']['via_options']
      )
    end
  end


  get '/' do
    erb :form
  end

  post '/' do
    # `pid` must be in the form UMS12345678 or 12345678
    if match = params[:pid].match(/(UMS)?([0-9]{8})/i) and !match[2].blank?
      if @patron = Patron.find_by_ums($2) and @patron.valid?
        mail_barcode_reminder(@patron)
        @success = 'An email is on the way!'
      else
        @error = "We couldn't find your UMS number in our system."
      end
    else
      @error = 'The UMS number you entered is invalid.'
    end

    erb :form
  end

  # start the server if ruby file executed directly
  run! if app_file == $0
end

require 'sinatra/base'
require 'erb'
require 'oci8'
require 'pony'

class Barcode < Sinatra::Base
  CONFIG = YAML.load_file(File.join(File.dirname(__FILE__), "config.yml"))

  class Patron
    attr :first_name, :last_name, :barcode, :patron_group, :email
    def initialize(arr)
      # If any of the initializing fields are blank, return nil
      return nil if arr.any? {|field| field.blank?}

      @first_name = arr[0]
      @last_name = arr[1]
      @barcode = arr[2]
      @patron_group = arr[3]
      @email = arr[4]
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
        r = OCI8.new(CONFIG['username'], CONFIG['password']).exec(sql, id).fetch
        return r.nil? ? nil : Patron.new(r)
      rescue
        # log error here
        return nil
      end
    end
  end

  helpers do
    def mail_barcode_reminder(patron)
      Pony.mail(
        :to      => patron.email,
        :from    => 'brice@atropos.lib.umb.edu',
        :subject => 'Barcode Recovery',
        :body    => erb(:email, :locals => { :patron => self }),
        :via => :smtp,
        :via_options => {
          :address              => 'smtp.gmail.com',
          :port                 => '587',
          :enable_starttls_auto => true,
          :user_name            => 'task.notifier8@gmail.com',
          :password             => 'circulate',
          :authentication       => :plain, # :plain, :login, :cram_md5, no auth by default
          :domain               => "localhost.localdomain" # the HELO domain provided by the client to the server
        })
    end
  end


  get '/' do
    erb :form
  end

  post '/' do
    match = params[:pid].match /(UMS)?([0-9]{8})/i
    if match
      id = match[2]
    else
      raise "Invalid UMS number"
    end

    if @patron = Patron.find_by_ums(id)
      mail_barcode_reminder(@patron)
      @success = 'An email is on the way!'
    else
      @error = "We couldn't find your UMS number in our system."
    end

    erb :form
  end

  # start the server if ruby file executed directly
  run! if app_file == $0
end

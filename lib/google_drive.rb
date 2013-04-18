require 'google/api_client'
require 'google/api_client/client_secrets'
require 'tempfile'

class GoogleDrive
  
 
  
  attr_accessor :client, :drive
  
  def initialize 
        @client = Google::APIClient.new
        @drive = @client.discovered_api('drive', 'v2')
        
        key = Google::APIClient::PKCS12.load_key(ENV["GOOGLE_KEY_FILENAME"], ENV["GOOGLE_KEY_PASSWORD"])
        service_account = Google::APIClient::JWTAsserter.new(
            ENV["GOOGLE_SERVICE_ACCOUNT"],
            'https://www.googleapis.com/auth/drive',
            key)
            
        @client.authorization = service_account.authorize("library@wmu.se")
  end


  
  # this take an array of items. like [ { { :title => "foo", :description => "blah blah", url =>   }  }]
  def upload_items(items)
    items.each { |item| upload_item(item) }
  end
  
  # this uploads the item to GDrive. It takes a hash of metadata ( :title, and :description)
  # a file object, which is writen to a tmp file
  # and a uuid of a parent folder, which is generated for the user. 
  def upload_item(item, file, parent = '0BxnZXCons72AYXZOTVVrdGk0bTg' )
        tmp_file = Tempfile.new('mendeley').tap do |f|
          f.binmode # must be in binary mode
          f.write file
          f.rewind
        end
        
        metadata = @drive.files.insert.request_schema.new({
          'title' => item[:title],
          'description' => item[:description],
          'mimeType' => 'application/pdf',
          'parents' => [{'id' => parent}]
        }) 
        
        conn = Faraday.default_connection
        conn.options[:timeout] = 500 
        conn.options[:open_timeout] = 2 
        
        media = Google::APIClient::UploadIO.new(tmp_file, 'application/pdf')       
        result = @client.execute(:api_method => @drive.files.insert,
                           :parameters => { 'uploadType' => 'multipart', 'alt' => 'json' },
                           :body_object => metadata,
                           :media => media, 
                           :connection => conn
                           )
        tmp_file.close!
       result.data
  end
  
  # this creates a new ingest folder for the user.
  def create_user_ingest_folder(user_name, parent = '0BxnZXCons72AYXZOTVVrdGk0bTg')
     metadata = @drive.files.insert.request_schema.new({
        'title' => user_name,
        'mimeType' => "application/vnd.google-apps.folder",
        'parents' => [{'id' => parent}]
      })
     result = @client.execute( :api_method => @drive.files.insert, :body_object => metadata )
     result.data["id"]
  end
  
  
end
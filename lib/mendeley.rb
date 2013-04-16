require 'faraday'
require 'faraday_middleware'
require 'simple_oauth'
require 'tempfile'
class Mendeley
  attr_reader :token, :secret

  #
  # Create a new mendeley object
  #
  # @param token [String] the user's access token
  # @param secret [String] the user's access secret
  #
  def initialize(token, secret)
    @token, @secret = token, secret
  end

  #
  # Sends a get request to the mendeley API
  #
  # @param path [String] the path of the request to execute
  # @return [Hash] the json returned by the server
  #
  def get(path)
    connection.get do |req|
      req.url path
    end.body
  end
  
  #
   # Sends a get request to the mendeley API
   #
   # @param path [String] the path of the request to execute
   # @return [TempFile] the file returned by the server
   #
   def download(path)
      downloader.get do |req|
        req.url path
      end.body
   end

  
  
  #
   # Sends a get request to the mendeley API to download a pdf
   #
   # @param path [String] the path of the request to execute
   # @return [IO] the file returned by the server
   #

  def connection(response_type = :json)
    @connection ||= Faraday.new(url: 'http://api.mendeley.com') do |connection|
      connection.request  :url_encoded
      connection.request  :oauth, oauth_data
      connection.response :json, content_type: //
      connection.adapter  *Faraday.default_adapter
    end
  end
  
  def downloader
   @downloader ||= Faraday.new(url: 'http://api.mendeley.com') do |connection|
      connection.request  :url_encoded
      connection.request  :oauth, oauth_data
      connection.adapter  *Faraday.default_adapter
    end
  end

  def oauth_data
    {
      consumer_key: consumer_key,
      consumer_secret: consumer_secret,
      token: token,
      token_secret: secret
    }
  end

  def consumer_key
    ENV['MENDELEY_KEY']
  end

  def consumer_secret
    ENV['MENDELEY_SECRET']
  end
end
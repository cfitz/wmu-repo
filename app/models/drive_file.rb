class DriveFile
  include Mongoid::Document
  
  field :file_hash, type: String
  field :drive_uuid, type: String  
  field :drive_url, type: String
  
  validates(:file_hash, :presence => true)
  validates(:drive_uuid, :presence => true)
  
  
end
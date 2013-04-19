require 'open-uri'

class User
  include Mongoid::Document
  attr_protected :provider, :uid, :name, :email
  
  field :provider, type: String
  field :uid, type: String
  field :name, type: String
  field :email, type: String
  field :token, type: String
  field :secret, type: String
  field :ingest_folder, type: String
  field :sync_folders, type: Array, :default => []
  
 # embeds_many :sync_folders 
#  accepts_nested_attributes_for :sync_folders, allow_destroy: true
  
  has_and_belongs_to_many :items
  
  def self.create_with_omniauth(auth)
    create! do |user|
      user.provider = auth['provider']
      user.uid = auth['uid']
      if auth['info']
         user.name = auth['info']['name'] || "UNKNOWN USER #{rand(100)}"
         user.email = auth['info']['email'] || ""
         user.uid = auth["uid"]  
         user.token = auth['credentials']['token']
         user.secret = auth['credentials']['secret']
      end
      user.ingest_folder = GoogleDrive.new.create_user_ingest_folder(user.name)
    end
  end
  
  def show_folders
    return mendeley.get('/oapi/library/folders/')
  end
  
  def show_folder_items(folder_id, page = "0")
    if folder_id.include?(":") # group folders have the group id prefixed. 
      group_id, folder_id = folder_id.split(":")
      return mendeley.get("/oapi/library/groups/#{group_id}/folders/#{folder_id}?page=#{page}")
    else
      return mendeley.get("/oapi/library/folders/#{folder_id}?page=#{page}")
    end
  end
  
  def show_document_details(document_id, group_id = nil)
    if group_id
      return mendeley.get("/oapi/library/groups/#{group_id}/#{document_id}")
    else
      return mendeley.get("/oapi/library/documents/#{document_id}")
    end
  end
  
  def show_library
    return mendeley.get('/oapi/library')
  end
  
  def show_groups
    groups = mendeley.get('/oapi/library/groups')
    groups.each { |group| group["folders"] = show_group_collections(group["id"]) }
    groups
  end

  def show_group_collections(group_id)
    mendeley.get("/oapi/library/groups/#{group_id}/folders")
  end
  
  def download_document(document_id, file_hash, group_id = nil)
     if group_id
         return mendeley.download("/oapi/library/documents/#{document_id}/file/#{file_hash}/#{group_id}")
      else
        return mendeley.download("/oapi/library/documents/#{document_id}/file/#{file_hash}")
      end
  end
  
  def self.sync_all_folders
    User.all.each do |user|
      puts "Syncing User: #{user.id}"
      user.sync_folders.each do |folder| 
        puts "Syncing Folder: #{folder}"
        FolderSync.process(user, folder)
      end
    end
  end
  
  protected
  
  def mendeley
    Mendeley.new(self.token, self.secret)
  end
  
end

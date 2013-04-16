class SyncFolder
  include Mongoid::Document
  
  field :folder_id, type: String
  field :parent_group, type: String # for folders that are part of a group
  
  validates_uniqueness_of :folder_id
  
  def to_params
    folder_id
  end
    
  
  
end
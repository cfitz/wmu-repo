require 'citeproc'
class Item
  include Mongoid::Document
  
  field :mendeley_metadata, type: Hash
  field :mendeley_version, type: Time
  field :mendeley_id, type: String
  field :mendeley_group_id, type: String
  field :mendeley_canonical_id, type: String
  
  has_and_belongs_to_many :users
  embeds_many :drive_files do
    def find_by_file_hash(file_hash)
      where( file_hash: file_hash).first
    end
  end
  
  validates(:mendeley_id, :presence => true)
  validates(:mendeley_metadata, :presence => true)
  validates(:mendeley_version, :presence => true)
  
  after_validation do |item|
    item.mendeley_canonical_id = item.mendeley_metadata["canonical_id"]
  end
  
  
  
  # right now only allowing one pdf / record. will update later.
  # optional values of position index for files, which alls the document title to reflex the order of the file. 
  def to_drive_metadata(position = 1, number_of_files = 1 ) 
    title = "#{self.mendeley_metadata["title"][0..100]} -- (#{position}/#{number_of_files})" 
    { :title => title, :description => self.to_bibtex.to_s }
  end
  
  def to_bibtex
    BibtexConverter.process(self.mendeley_metadata)
  end
  
  def to_apa
    CiteProc.process self.to_bibtex.to_citeproc, :style => :apa
  end
  
  

end
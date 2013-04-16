class FolderSync
  
  class << self
    def process(user, folder)
      @client = GoogleDrive.new
    
      items = []
      group_id = folder.include?(":") ? folder.split(":").first : nil 
      query = user.show_folder_items(folder)
      query["documents"].map { |i| items << i }
      last_page = ( query["total_pages"].to_i - 1 ) 
      (1..last_page).each  { |page| user.show_folder_items(folder, page)["documents"].map { |i| items << i } } 
      items.each do |item|  
        i = find_item(item, group_id )
        unless i.mendeley_version ==  Time.mongoize(item["version"]) # if the version is different, we update the record.
          i.mendeley_version = item["version"] 
          i.mendeley_metadata = user.show_document_details(i.mendeley_id, i.mendeley_group_id)
          number_of_files = i.mendeley_metadata["files"].length
          i.mendeley_metadata["files"].each_with_index do |file, index|
            unless i.drive_files.find_by_file_hash( file["file_hash"] )
              drive_metadata = i.to_drive_metadata(index+1, number_of_files)
              drive_response = @client.upload_item( drive_metadata, user.download_document(i.mendeley_id, file["file_hash"], i.mendeley_group_id  ), user.ingest_folder)
              drive_file = DriveFile.create(:drive_uuid => drive_response["id"], :drive_url => drive_response["alternateLink"], :file_hash => file["file_hash"] )
              i.drive_files << drive_file
            end
          end
          user.items << i
          i.save
        end
      end
      user.save
    end
    
    # finds an item in Mongo using the json returned from Mendeley
    def find_item(item_json, group_id = nil)
      item ||= Item.where(:mendeley_id => item_json["id"], :mendeley_group_id => group_id ).first
      item ||= Item.new(:mendeley_id => item_json["id"], :mendeley_group_id => group_id )
      item
    end
  
 end

 private_class_method :find_item
  
end
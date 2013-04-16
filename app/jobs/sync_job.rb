class SyncJob < Struct.new(:user_id)
  def perform
    user = User.find(user_id)
    user.sync_folders.each { |folder| FolderSync.process(user, folder)  }
  end
end
module UsersHelper



  def group_list(groups)
    content_tag :ul, :class => "name nav-list" do
     groups.map do |group|
       content_tag(:li, group["name"]) +
       folder_list(group["folders"], group["id"]) 
     end.join("").html_safe  
    end
  end
  
  def folder_list(list, group_id = nil)
    content_tag :ul, :class => "name nav-list" do
      list.map do |folder|
        id = folder_id(folder["id"], group_id)
        content_tag(:li) do
          content_tag(:label, folder["name"], :class => "checkbox inline") <<             
            check_box_tag( "sync_folders_#{id.gsub(":", "_")}" , id, @user.sync_folders.include?(id), :name => "user[sync_folders][]", :class => "sync_folders" ) 
        end.html_safe
      end.join("").html_safe
    end.html_safe
  end
    
  def folder_id(id, group_id)
    group_id ? "#{group_id}:#{id}" : id
  end


end

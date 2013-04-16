class UsersController < ApplicationController
   respond_to :html, :json
  def show
     @user = User.find(params[:id])
  end
  
  def edit
    @user = User.find(params[:id])
  end
  
  def update
      @user = User.find(params[:id])  
      if @user.update_attributes(params[:user])  
        flash[:notice] = "Successfully updated user."  
      end  
      respond_with(@user)  
  end
 
end
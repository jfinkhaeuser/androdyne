class UserController < ApplicationController
  before_filter :require_user, :only => [:show]

  def show
    @user = User.find(params[:id])
    render :action => :show
  end

end

class HomeController < ApplicationController

  def index
    if current_user
      @packages = current_user.packages.paginate(:page => params[:page], :per_page => 5, :order => 'name ASC')
    end
  end

end

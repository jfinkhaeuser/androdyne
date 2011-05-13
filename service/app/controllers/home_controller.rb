class HomeController < ApplicationController
#  before_filter :require_user # FIXME

  def index
    if current_user
      @packages = current_user.packages.all.paginate(:page => params[:page], :per_page => 5, :order => 'name ASC')
    end
  end

end

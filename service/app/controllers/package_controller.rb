class PackageController < ApplicationController
  before_filter :require_user

  def index
    @packages = current_user.packages.paginate(:page => params[:page], :order => 'name ASC')
  end


  def new
    @package = Package.new
  end


  def edit
    @package = current_user.packages.find(params[:id])
  end


  def show
    @package = current_user.packages.find(params[:id])
  end


  def create
    @package = current_user.packages.new(params[:package])
    if @package.save
      flash[:notice] = "Package created!"
      redirect_back_or_default package_index_path
    else
      render :action => :new
    end
  end
end

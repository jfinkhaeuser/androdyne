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

    groups = @package.stacktraces.sum(
        'occurrences.count',
        :include => [ :occurrences ],
        :group => :version_code
    )

    @trace_groups = {}
    groups.each do |key|
      version_code = key[0]
      group = {
        :version_code => version_code,
        :count => key[1],
      }

      traces = @package.stacktraces.where(:version_code => version_code)
      group[:stacktraces] = traces
      group[:package_id] = traces[0].package_id

      @trace_groups[traces[0].version] = group
    end
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

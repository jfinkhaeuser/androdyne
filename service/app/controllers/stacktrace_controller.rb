class StacktraceController < ApplicationController
  before_filter :require_user

  def show
    packages = current_user.packages.where(:id => params[:package_id])
    @package = packages[0]
    traces = @package.stacktraces.where(:id => params[:id])
    @trace = traces[0]
  end

end

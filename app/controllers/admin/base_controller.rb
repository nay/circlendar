class Admin::BaseController < ApplicationController
  layout "admin"
  before_action :require_admin

  private

  def require_admin
    raise ActiveRecord::RecordNotFound unless Current.user&.admin?
  end
end

class BannersController < ApplicationController
  def dismiss_backup_email
    session.delete(:show_backup_email_banner)
    head :no_content
  end
end

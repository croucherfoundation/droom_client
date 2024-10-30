class EmailsController < ApplicationController
  respond_to :html, :json
  layout :no_layout_if_pjax

  def new
    if current_user.present?
      @user = User.find(current_user.id)
      render :partial => 'shared/account_settings/emails/fields'
    end
  end

end
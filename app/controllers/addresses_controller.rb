class AddressesController < ApplicationController
  respond_to :html, :json
  layout :no_layout_if_pjax

  def new
    if current_user.present?
      @user = User.find(current_user.id)
      render :partial => 'droom_client/shared/contact/addresses/fields'
    end
  end

end
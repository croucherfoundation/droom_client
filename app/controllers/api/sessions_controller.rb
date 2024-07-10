class Api::SessionsController < ApplicationController
  protect_from_forgery except: :sign_in
  respond_to :json
  skip_before_action :verify_authenticity_token, raise: false

  def new
    render
  end

  def create
    if sign_in_params.present?
      user = User.sign_in(sign_in_params.to_h)

      if user
        if params[:module] == 'scholar-portal' && !(user.admin? || (["Staff","Developers"].include? user.user_groups))
          @person = user.person
          @awards = @person.awards
          award_years = @awards.map(&:year) rescue []
          p "Award years: #{award_years}"
          unless award_years.include?(2024)
            return render json: { error_message: 'Your account does not have permission to access the portal.' }, status: 401
          end
        end

        RequestStore.store[:current_user] = user
        set_auth_cookie_for(user)
        cookie_name = ENV['DROOM_AUTH_COOKIE'] || Settings.auth.cookie_name
        sign_in_cookie = cookies["#{cookie_name}"]
        if sign_in_cookie
          begin
            parsed_cookie = JSON.parse(sign_in_cookie)
            user_data = {
              _s: parsed_cookie[0],
              _k: parsed_cookie[1][0],
              _d: parsed_cookie[1][1]
            }
            render json: user_data
          rescue JSON::ParserError, NoMethodError => e
            return sing_in_error
          end
        else
          return sing_in_error
        end
      else
        return sing_in_error
      end
    else
      return sing_in_error
    end
  end

  def destroy
    current_user.sign_out!
    name = current_user.formal_name
    RequestStore.store.delete :current_user
    unset_auth_cookie
    reset_session
    if request.xhr? || (request.headers["x-api-key"] && request.headers["x-api-key"].present?)
      head :ok
    else
      flash[:notice] = t("flash.goodbye", name: name).html_safe
      redirect_to after_sign_out_path_for(current_user), method: "get"
    end
  end

  protected

  def sign_in_params
    if params[:user]
      params.require(:user).permit(:email, :password, :remember_me)
    else
      {}
    end
  end

  def sing_in_error
    render json: { error_message: "Email or password is incorrect." }, status: 400
  end

end

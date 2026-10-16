class UserSessionsController < ApplicationController
  include DroomAuthentication
  before_action :require_no_user!, only: [:new, :create]
  before_action :authenticate_user!, only: [:destroy]
  skip_before_action :verify_authenticity_token, only: [:destroy], raise: false

  # From this date, signing in with a backup email is no longer allowed;
  # until then we only show a reminder banner (see #flag_backup_email_sign_in).
  BACKUP_EMAIL_ENFORCEMENT_DATE = Date.new(2026, 9, 9)

  def new
    render
  end

  def create
    if user = User.sign_in(sign_in_params.to_h)
      if user.confirmed?
        if backup_email_login_blocked?(user)
          RequestStore.store.delete :current_user
          unset_auth_cookie
          reset_session
          flash[:alert] = "Please log in with your primary email address. If you need to update your primary email, use the password reset flow."
          redirect_to droom_client.sign_in_path and return
        end
        RequestStore.store[:current_user] = user
        set_auth_cookie_for(user)
        flag_backup_email_sign_in(user)
      else
        RequestStore.store.delete :current_user
        unset_auth_cookie
        reset_session
        if request.referer.present?
          redirect_to_url = redirect_url(request.referer, { not_confirmed: true })
        else
          redirect_to_url = redirect_url(droom_client.sign_in_path, { not_confirmed: true })
        end
        redirect_to redirect_to_url and return
      end
      unless request.xhr?
        set_notice(t('notifications.authentication.login_success', name: user.name))
      end
      destination = params[:destination]
      if destination.present? && destination =~ /^\//
        redirect_to params[:destination]
      elsif destination.present? && params[:begin_application]
        redirect_to destination
      else
          redirect_to after_sign_in_path_for(user)
      end
    else
      # flash[:error] = t("flash.not_recognised").html_safe
      redirect_to_url = droom_client.sign_in_path
      sso = params[:sso]
      sig = params[:sig]

      if params[:destination].present? && params[:begin_application]
        redirect_to_url = "#{redirect_to_url}?destination=#{params[:destination]}&begin_application=true"
      elsif sso.present? && sig.present?
        redirect_to_url = "#{redirect_to_url}?sso=#{sso}&sig=#{sig}"
      else
        redirect_to_url = "#{request.referer || redirect_to_url}"
      end
      redirect_to_url = redirect_url(redirect_to_url, { failed: true })
      redirect_to redirect_to_url
    end
  end

  def destroy
    current_user.sign_out!
    name = current_user.name
    RequestStore.store.delete :current_user
    unset_auth_cookie
    reset_session
    if request.xhr?
      head :ok
    else
      set_notice(t('notifications.authentication.logout', name: name))
      if params[:back_to].present?
        redirect_to params[:back_to], method: "get"
      else
        redirect_to after_sign_out_path_for(current_user), method: "get"
      end
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

  # Flag the session when a user signs in using an email that is not their
  # primary email (i.e. a backup email), so the layout can show a banner
  # reminding them to use their primary email in future.
  def flag_backup_email_sign_in(user)
    submitted = sign_in_params[:email].to_s.strip.downcase
    primary = user.try(:primary_email).to_s.strip.downcase
    if submitted.present? && primary.present? && submitted != primary
      session[:show_backup_email_banner] = true
    else
      session.delete(:show_backup_email_banner)
    end
  end

  # On or after the enforcement date, a user may no longer sign in using a
  # backup email; they must use their primary email instead.
  def backup_email_login_blocked?(user)
    return false if Date.current < BACKUP_EMAIL_ENFORCEMENT_DATE
    submitted = sign_in_params[:email].to_s.strip.downcase
    primary = user.try(:primary_email).to_s.strip.downcase
    submitted.present? && primary.present? && submitted != primary
  end

  def redirect_url(redirect_to_url, additional_params = {})
    uri = URI.parse(redirect_to_url)
    query_params = Rack::Utils.parse_query(uri.query || '')

    # Remove unwanted or conflicting parameters
    query_params.delete('failed')
    query_params.delete('not_confirmed')

    # Merge additional parameters
    query_params.merge!(additional_params)

    # Reconstruct the URL
    uri.query = query_params.to_query
    uri.query.present? ? uri.to_s : uri.to_s.chomp('?')
  end
end

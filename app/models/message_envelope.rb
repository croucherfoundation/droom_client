class MessageEnvelope
  include Her::JsonApi::Model

  use_api DROOM
  collection_path "/api/message_envelopes"
  include_root_in_json true
  parse_root_in_json false

  belongs_to :message

  def for_mandrill_message(with_html=false, survey_code=nil, test_email=false, options={})
    if options[:review_id].present?
      @review_id = options[:review_id]
    end
    if options[:reminder].present?
      @reminder = options[:reminder]
    end
    if options[:award_id].present?
      @award_id = options[:award_id]
    end
    if options[:event_application].present?
      @event_application = options[:event_application]
    end

    @survey_code = survey_code
    data = {
      "from_name" => message.from_name.presence || ENV['EMAIL_FROM_NAME'],
      "from_email" => message.from_email.presence || ENV['EMAIL_FROM'],
      "track_opens" => true,
      "to" => send_address(test_email),
      "subject" => render_subject
    }
    data["html"] = render_html if with_html
    data
  end

  def render_html
    for_view_online
    layout = message.template.present? ? message.template.layout : 'default'

    template_path =
      if system_name == 'core_notify'
        "layouts/#{layout}"
      elsif system_name == 'publishing' || system_name == 'publishing_symposium'
        "event_applications/layouts/#{layout}"
      else
        "rounds/layouts/#{layout}"
      end

    ::ApplicationController.renderer.new.render_to_string(
                                        template: template_path, 
                                        locals: {envelope: @envelope, subject: @subject, summary: @summary, body: @body, applicant: @applicant, system_name: system_name, reminder: @reminder},
                                        layout: false)
  end

  def render_subject
    unless @subject
      @subject = self.rendered_subject = message.render_subject_for(applicant)
    end

    @subject
  end

  def render_summary
    unless @summary
      @summary = self.rendered_summary = message.render_summary_for(applicant)
    end
    @summary
  end

  def send_address(test_email=false)
    unless Rails.env.production? || test_email
      self.email = Settings.email.sandbox if applicant.present?
    end
    email_address = [
      {
        "name" => applicant&.name.presence || 'Applicant',
        "email" => email,
        "type":"to"
        }
    ]
    if message.bcc.present?
      bcc_emails = message.bcc.split(',')
      bcc_emails.each do |bcc_email|
        email_address << {
          "name" => applicant&.name.presence || 'Applicant',
          "email" =>bcc_email,
          "type" => "bcc"
        }
      end
    else
      email_address << {
        "name" => applicant&.name.presence || 'Applicant',
        "email" =>Settings.email.it_support,
        "type" => "bcc"
      }
    end

    email_address
  end

  def render_body
    return @body if @body
  
    @body = if @reminder
              message.render_body_for(applicant, reminder: @reminder)
            elsif @award_id
              message.render_body_for(applicant, award_id: @award_id)
            elsif @review_id.present?
              message.render_body_for_reviewer(applicant, review_id: @review_id)
            elsif @event_application.present?
              message.render_body_for(applicant, event_application: @event_application)
            else
              message.render_body_for(applicant, survey_code: @survey_code)
            end
  
    self.rendered_body = @body
  end

  def for_view_online
    @envelope = self
    return render_summary, render_subject, render_body, applicant
  end

  def applicant
    @applicant ||= Application.find(application_id) if application_id? && system_name == 'application'
    @applicant ||= EventApplication.find(application_id) if application_id? && system_name == 'publishing'
    @applicant ||= User.find(user_uid) if user_uid && (system_name == 'publishing_symposium' || system_name == 'application_reviewer')
    @applicant ||= Person.find_by_uid(person_uid) if person_uid.present? && system_name == 'core_notify'
    @applicant
  end
  
end
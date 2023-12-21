class MessageEnvelope
  include Her::JsonApi::Model

  use_api DROOM
  collection_path "/api/message_envelopes"
  include_root_in_json true
  parse_root_in_json false

  belongs_to :message

  def for_mandrill_message(with_html=false)
    data = {
      "from_name" => message.from_name.presence || ENV['EMAIL_FROM_NAME'],
      "from_email" => message.from_email.presence || ENV['EMAIL_FROM'],
      "track_opens" => true,
      "to" => send_address,
      "subject" => render_subject
    }
    data["html"] = render_html if with_html
    data
  end

  def render_html
    for_view_online
    layout = message.template.present? ? message.template.layout : 'default'
    ::ApplicationController.renderer.new.render_to_string(
                                        template: "rounds/layouts/#{layout}", 
                                        locals: {envelope: @envelope, subject: @subject, summary: @summary, body: @body, applicant: @applicant},
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

  def send_address
    unless Rails.env.production?
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
    unless @body
      @body = self.rendered_body = message.render_body_for(applicant)
    end
    @body
  end

  def for_view_online
    @envelope = self
    return render_summary, render_subject, render_body, applicant
  end

  def applicant
    @applicant ||= Application.find(application_id) if application_id?
  end
  
end
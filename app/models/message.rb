class Message
  include Her::JsonApi::Model

  use_api DROOM
  collection_path "/api/messages"
  include_root_in_json true
  parse_root_in_json false

  belongs_to :template, class_name: 'MessageTemplate', optional: true

  def render_body_for(person, options={})
    survey_code = options[:survey_code]
    reminder = options[:reminder]
    award_id = options[:award_id]
    message_body = template.present? ? template.body : body
    attributes = person.present? ? person.for_email : for_email
    message_body = transform_body_for_survey(person, message_body) if person.class.name == 'EventApplication' || person.class.name == 'User'
    message_body = transform_body_for_test_survey(survey_code, message_body) if survey_code.present?
    message_body = transform_body_for_reminder(person, message_body) if reminder.present?
    message_body = transform_body_for_notify(person, message_body, award_id) if award_id.present?

    if template.present? && template&.layout == 'message'
      html = Nokogiri::HTML.parse(message_body)
      html.css('a[href]').each do |a|
        a['style'] = 'text-decoration: none; color: #000000; cursor: default'
      end
      Mustache.render(html.to_html, attributes)
    else
      Mustache.render(message_body, attributes)
    end

  end

  def render_body_for_reviewer(person, options={})
    review_id = options[:review_id]
    message_body = template.present? ? template.body : body
    attributes = person.present? ? person.for_email : for_email
    message_body = transform_body_for_review(person, message_body, review_id) if person.class.name == 'User'
    if template.present? && template&.layout == 'message'
      html = Nokogiri::HTML.parse(message_body)
      html.css('a[href]').each do |a|
        a['style'] = 'text-decoration: none; color: #000000; cursor: default'
      end
      Mustache.render(html.to_html, attributes)
    else
      Mustache.render(message_body, attributes)
    end

  end

  def transform_body_for_review(person, body, review_id)
    review = Review.find(review_id)
    if review.present?
      application = review.application
      short_description = ActionController::Base.helpers.sanitize(application.short_description.to_s, tags: ['a', 'b', 'i', 'ol', 'ul', 'li', 'h2', 'h3'])
      invitation_url = review.invitation_url
      invitation_link = <<~HTML.strip
        <span style='display: inline-block'>
          <a
            href="#{invitation_url}"
            target="_blank"
            style="text-decoration: none; color: #ee3a43; cursor: pointer;">
            <font color="#ee3a43">here</font>
          </a>
        </span>
      HTML

      invitation_link_button = <<~HTML.strip
        <table border="0" cellspacing="0" cellpadding="0">
          <tr>
            <td align="center" style="border-radius: 30px;padding: 10px 25px 10px 25px;" bgcolor="#ee3a43">
              <a href="#{invitation_url}"
                target="_blank"
                style="background-color: #ee3a43;
                        border-radius: 30px;
                        display: inline-block;
                        color: #ffffff;
                        font-family: Arial, sans-serif;
                        font-size: 16px;
                        font-weight: bold;
                        line-height: 40px;
                        text-align: center;
                        text-decoration: none;
                        width: 200px;
                        -webkit-text-size-adjust: none;">
                <span style="color: #ffffff !important">Online application and reviewing toolkit &rarr;</span>
              </a>
            </td>
          </tr>
        </table>
      HTML

      round_name = <<~HTML.strip
        <span style='display: inline-block'>
          #{review.round_name}
        </span>
      HTML

      reviewer_deadline = <<~HTML.strip
        <span style='display: inline-block'>
          #{review.reviewer_deadline}
        </span>
      HTML

      body.gsub('{{reviewer_invitation_url}}', invitation_link)
          .gsub('{{round_name}}', round_name)
          .gsub('{{reviewer_invitation_button}}', invitation_link_button)
          .gsub('{{applicant_formal_name}}', review.application_formal_name)
          .gsub('{{university_name}}', review.application_university_name)
          .gsub('{{working_days}}', review.application_working_days)
          .gsub('{{course_title}}', review.application_course_title)
          .gsub('{{short_description}}', short_description)
          .gsub('{{reviewer_deadline}}', reviewer_deadline)
    end
  end

  def transform_body_for_survey(person, body)
    survey_url = person.class.name == 'EventApplication' ? person.survey_url : person.symposium_survey_url
    survey_link = <<~HTML.strip
      <span style='display: inline-block'>
        <a
          href="#{survey_url}"
          target="_blank"
          style="text-decoration: none; color: #ee3a43; cursor: pointer;">
          <font color="#ee3a43">here</font>
        </a>
      </span>
    HTML

    survey_link_button = <<~HTML.strip
      <table border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td align="center" style="border-radius: 30px;padding: 10px 25px 10px 25px;" bgcolor="#ee3a43">
            <a href="#{survey_url}"
              target="_blank"
              style="background-color: #ee3a43;
                      border-radius: 30px;
                      display: inline-block;
                      color: #ffffff;
                      font-family: Arial, sans-serif;
                      font-size: 16px;
                      font-weight: bold;
                      line-height: 40px;
                      text-align: center;
                      text-decoration: none;
                      width: 200px;
                      -webkit-text-size-adjust: none;">
              <span style="color: #ffffff !important">Go to survey form &rarr;</span>
            </a>
          </td>
        </tr>
      </table>
    HTML

    name_of_course = <<~HTML.strip
      <span style='display: inline-block'>
        #{person.attended_event_name&.strip&.gsub(/\u00A0/, '')}
      </span>
    HTML

    body.gsub('{{survey_url}}', survey_link).gsub('{{name_of_course}}', name_of_course).gsub('{{survey_url_button}}', survey_link_button)
  end

  def transform_body_for_test_survey(survey_code, body)
    survey_link = <<~HTML.strip
      <span style='display: inline-block'>
        <a
          href="#{ENV['PUB_URL']}/surveys/#{survey_code}/responses/test-survey"
          target='_blank'
          style='text-decoration: none; color: #ee3a43; cursor: pointer; display: inline-block;'>
          <font color="#ee3a43">here</font>
        </a>
      </span>
    HTML

    name_of_course = <<~HTML.strip
      <span style='display: inline-block'>Testing course</span>
    HTML

    body.gsub('{{survey_url}}', survey_link).gsub('{{name_of_course}}', name_of_course)
  end

  def transform_body_for_reminder(person, body)
    resume_link = person.reminder_resume_applicaiton_link
    
    reminder_resume_link = <<~HTML.strip
      <span style='display: inline-block'>
        <a
          href="#{resume_link}"
          target="_blank"
          style="text-decoration: none; color: #ee3a43; cursor: pointer;">
          <font color="#ee3a43">Resume application</font>
        </a>
      </span>
    HTML

    round_deadline = <<~HTML.strip
      <span style='display: inline-block'>
        #{person.round_deadline}
      </span>
    HTML

    body.gsub('{{resume_application}}', reminder_resume_link).gsub('{{round_deadline}}', round_deadline)
  end

  def transform_body_for_notify(person, body, award_id)
    award = Award.find_by(id: award_id)
    return body unless award
  
    award_type_name = award.award_type&.name || " "
  
    issue_date = award.issued_at&.strftime('%-d %B %Y at%l%P') || " "
  
    award_type_name = <<~HTML.strip
      <span style='display: inline-block'>
        #{award_type_name}
      </span>
    HTML
  
    issue_date = <<~HTML.strip
      <span style='display: inline-block'>
        #{issue_date}
      </span>
    HTML
  
    body.gsub('{{award_type_name}}', award_type_name).gsub('{{issued_at}}', issue_date)
  end

  def render_summary_for(person)
    message_summary = template.present? ? template.summary : summary
    attributes = person.present? ? person.for_email : for_email
    Mustache.render(message_summary || "", attributes)
  end

  def render_subject_for(person)
    message_subject = template.present? ? template.subject : subject
    attributes = person.present? ? person.for_email : for_email
    Mustache.render(message_subject, attributes)
  end

  def for_email
    {
      name: 'Applicant',
      informal_name: 'Applicant',
      formal_name: 'Applicant',
      award_type_name: 'Croucher Scholarship/Fellowship/Research Studentship/Science Communication Studentship'
    }
  end

end

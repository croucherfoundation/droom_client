class Message
  include Her::JsonApi::Model

  use_api DROOM
  collection_path "/api/messages"
  include_root_in_json true
  parse_root_in_json false

  belongs_to :template, class_name: 'MessageTemplate', optional: true

  def render_body_for(person, options={})
    survey_code = options[:survey_code]
    message_body = template.present? ? template.body : body
    attributes = person.present? ? person.for_email : for_email
    message_body = transform_body_for_survey(person, message_body) if person.class.name == 'EventApplication' || person.class.name == 'User'
    message_body = transform_body_for_test_survey(survey_code, message_body) if survey_code.present?
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

    name_of_course = <<~HTML.strip
      <span style='display: inline-block'>
        #{person.attended_event_name&.strip&.gsub(/\u00A0/, '')}
      </span>
    HTML

    body.gsub('{{survey_url}}', survey_link).gsub('{{name_of_course}}', name_of_course)
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

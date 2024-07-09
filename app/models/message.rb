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
    message_body = transform_body_for_survey(person, message_body) if person.class.name == 'EventApplication'
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
    survey_link = <<~HTML
      <h3 style="margin: 0;">
        <a 
          href="#{person.survey_url}" 
          target="_blank" 
          style="text-decoration: none; color: red; cursor: pointer;">
          <font color="red">&rarr; Click here to provide your feedback</font>
        </a>
      </h3>
    HTML
    body.gsub('{{survey_url}}', survey_link)
  end  

  def transform_body_for_test_survey(survey_code, body)
    survey_link = <<~HTML
      <h3 style="margin: 0;">
        <a 
          href="#{ENV['PUB_URL']}/surveys/#{survey_code}/applications/test-survey/response" 
          target='_blank'
          style='text-decoration: none; color: red; cursor: pointer;'>
          <font color="red">&rarr; Click here to provide your feedback</font>
          </a>
      </h3>
    HTML
    body.gsub('{{survey_url}}', survey_link)
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
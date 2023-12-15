class Message
  include Her::JsonApi::Model

  use_api DROOM
  collection_path "/api/messages"
  include_root_in_json true
  parse_root_in_json false

  belongs_to :template, class_name: 'MessageTemplate', optional: true

  def render_body_for(person)
    message_body = template.present? ? template.body : body
    attributes = person.present? ? person.for_email : for_email

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
      name: 'Scholar',
      informal_name: 'Scholar',
      formal_name: 'Scholar'
    }
  end
  
end
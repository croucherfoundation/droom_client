class MessageTemplate
  include Her::JsonApi::Model

  use_api DROOM
  collection_path "/api/message_templates"
  include_root_in_json true
  parse_root_in_json false

  def render_body_for(person)
    if layout == 'message'
      html = Nokogiri::HTML.parse(body)
      html.css('a[href]').each do |a|
        a['style'] = 'text-decoration: none; color: #000000; cursor: default'
      end
      Mustache.render(html.to_html, person.for_email)
    else
      Mustache.render(body, person.for_email)
    end
  end

  def render_summary_for(person)
    Mustache.render(summary || "", person.for_email)
  end

  def render_subject_for(person)
    Mustache.render(subject, person.for_email)
  end

  def preview(person)
    return render_summary_for(person), render_subject_for(person), render_body_for(person)
  end
  
end
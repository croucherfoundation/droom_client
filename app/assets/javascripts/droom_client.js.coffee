# The user-chooser is a way of choosing or creating data room users and remembering their uids so that they 
# are allowed to sign in as screening judges or interviewers. Here we present a very compact suggestion-based
# interface.
#

jQuery ($) ->

  $.fn.user_chooser = () ->
    @each ->
      new UserChooser @

  class UserChooser
    constructor: (element) ->
      @_container = $(element)
      @_url = @_container.attr('data-url')
      @_suggestible_fields = @_container.find('input[suggestible]')
      @_uid_field = @_container.find('input[data-key="uid"]')
      @_required_fields = @_container.find('input[type="text"][required]')
      @_category_boxes = @_container.find('input.cat[type="checkbox"]')
      @_application_lis = @_container.find('li.app')
      @_application_boxes = @_container.find('input.app[type="checkbox"]')
      @_submitter = @_container.find('input[type="submit"]')
      @_list =  @_container.find('ul.suggestions')
      @_users = []
      @_filter = {}

      @_container.bind "submit", @submit
      @_category_boxes.bind "change", @checkForm
      @_application_boxes.bind "change", @checkForm
      @_category_boxes.bind "change", @toggleApplicationBoxes
      
      @toggleApplicationBoxes()
      @unSubmittable()
      
      @setFilter()
      @getData()

    getData: () =>
      @_list.addClass('waiting')
      $.getJSON @_url, @makeReady
    
    makeReady: (data) =>
      @_list.removeClass('waiting')
      @_users = data
      @suggest()
      @checkForm()
      @_suggestible_fields.bind 'keyup', @update
      @suggest()
      if uid = @_uid_field.val()
        # the lazy man's way to restore form state
        @_list.find("a##{uid}").trigger "click"

    setFilter: () =>
      @_suggestible_fields.each (i, fld) =>
        field = $(fld)
        val = field.val()
        @_filter[field.attr('data-key')] = val unless val is ""

    update: (e) =>
      if $.significantKeypress(e.which)
        @checkForm()
        if field = $(e.target)
          val = field.val()
          if !val or val is ""
            delete @_filter[field.attr('data-key')]
          else
            @_filter[field.attr('data-key')] = field.val()
          @suggest()

    matching_users: () =>
      if $.isEmptyObject(@_filter)
        return []
      else
        @_users.filter(@match) || []

    match: (user) =>
      for key, value of @_filter
        return false if user.attributes[key].toLowerCase().indexOf(value.toLowerCase()) == -1
      return true
      
    suggest: () =>
      @_list.empty()
      for user in @matching_users()
        do(user) =>
          icon= user.attributes.images.icon ? "/assets/no_thumb.png"
          li = $("<li class=\"suggestion\"><a href=\"#\" id=\"#{user.attributes.uid}\"><img src=\"#{icon}\" class=\"thumb\">#{user.attributes.colloquial_name}</a></li>").appendTo(@_list)
          li.find('a').bind "click", (e) =>
            e.preventDefault()
            @_list.find('li').each (ie, el) ->
              $(el).remove() unless el is li[0]
            li.find('a').unbind "click"
            li.addClass('chosen')
            $('<a class="reset minimal">reset</a>').appendTo(li).bind "click", @unchoose
            @choose(user)
      
    choose: (user) =>
      if user
        @_uid_field.val(user.attributes['uid'])
        @_suggestible_fields.each (i, fld) =>
          field = $(fld)
          key = field.attr('data-key')
          field.val(user.attributes[key])
          field.disable()
        @checkForm()

    unchoose: (e) =>
      e.preventDefault() if e
      @_uid_field.val('')
      @_suggestible_fields.each (i, fld) =>
        field = $(fld)
        key = field.attr('data-key')
        field.val(@_filter[key])
        field.enable()
      @checkForm()
      @suggest()

    checkForm: () =>
      valid = true
#     valid = @_category_boxes.filter(':checked').length or @_application_boxes.filter(':checked').length
      missing = @_required_fields.filter(":enabled").filter (i, fld) ->
        $.trim(fld.value) is ""
      .length
      valid = false if missing > 0
      if valid then @submittable() else @unSubmittable()

    toggleApplicationBoxes: () =>
      category_ids = []
      for box in @_category_boxes.filter(":checked").get()
        category_ids.push $(box).val()
      if category_ids.length > 0
        @_application_lis.hide().disable()
        for category_id in category_ids
          @_application_lis.filter("[data-category=\"#{category_id}\"]").show().enable()
      else
        @_application_lis.show().enable()

    submittable: () =>
      @_submitter.removeClass('disabled')
      @_blocked = false

    unSubmittable: () =>
      @_submitter.addClass('disabled')
      @_blocked = true

    submit: (e) =>
      e.preventDefault() if e and @_blocked



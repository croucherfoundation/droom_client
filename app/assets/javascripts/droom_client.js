(function() {
  jQuery(function($) {
    $('.password-reset-btn').on('click', function() {
      var $form = $(this).closest('form');
      var url = $form.attr('action');
      var formData = $form.serialize();

      $.ajax({
        url: url,
        type: 'POST',
        data: formData,
        complete: function(xhr) {
          if (xhr.status === 302 || xhr.status === 200) {
            $('#passwordModal').removeClass('modal-open');
            $("#passwordConfirmModal").addClass('modal-open');
          }
        }
      });
    });
  });

}).call(this);
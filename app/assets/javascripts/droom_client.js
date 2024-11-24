(function() {
  jQuery(function($) {

    $('.profile-upload-text, #profile-avatar').on('click', function() {
      $('#profile-upload').click();
    });
    // Preview the selected image
    $('#profile-upload').on('change', function(event) {
      var input = event.target;

      if (input.files && input.files[0]) {
        var reader = new FileReader();

        reader.onload = function(e) {
          $('#profile-avatar').attr('src', e.target.result);
          $('.profile-remove-button').css('display', 'block'); // Show remove button
        }

        reader.readAsDataURL(input.files[0]);
      }
    });

    $('.profile-remove-button').on('click', function(e) {
      e.preventDefault();
      let user_uid = $(this).data('user-uid');
      $.ajax({
        url: "/d/users/remove_profile/" + user_uid,
        type: 'GET',
        success: function(response) {
          window.location.reload();
        }
      });
    });

    // Password reset form
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
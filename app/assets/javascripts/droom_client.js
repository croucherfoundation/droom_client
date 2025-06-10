(function() {
  jQuery(function($) {

    $('.profile-upload-text, #profile-avatar').on('click', function() {
      $('#profile-upload').click();
    });
    // Preview the selected image
    $('#profile-upload').on('change', function(event) {
      var input = event.target;

      if (input.files && input.files[0]) {
        var file = input.files[0];
        
        // Check if the file is an image
        if (!file.type.match('image.*')) {
          alert('Please select an image file only.');
          $(this).val(''); // Clear the input
          return;
        }

        var reader = new FileReader();

        reader.onload = function(e) {
          $('#profile-avatar').attr('src', e.target.result);
          $('.profile-remove-button').css('display', 'block'); // Show remove button
          $('#remove_image').val('false');
        }

        reader.readAsDataURL(file);
      }
    });

    $('.profile-remove-button').on('click', function(e) {
      e.preventDefault();
      $('#remove_image').val('true');
      $('.profile-remove-button').css('display', 'none');
      $('#profile-upload').val('');
      $('#profile-avatar').attr('src', 'https://cmss.croucher.org.hk/assets/images/croucher-admin-1.png');
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
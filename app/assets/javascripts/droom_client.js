(function () {
  jQuery(function ($) {
    $('.profile-upload-text:not(#photo-upload-btn-modal2), #profile-avatar').on('click', function () {
      $('#profile-upload').click();
    });

    // Bind click event for modal2 elements in modify account settings page
    $(document).on('click', '#photo-upload-btn-modal2, #profile-avatar-modal2', function () {
      $('#profile-upload-modal2').click();
    });

    // Preview the selected image
    $('#profile-upload').on('change', function (event) {
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

        reader.onload = function (e) {
          $('#profile-avatar').attr('src', e.target.result);
          $('.profile-remove-button:not(.profile-remove-button-modal2)').css('display', 'block'); // Show remove button
          $('#remove_image').val('false');
        };

        reader.readAsDataURL(file);
      }
    });

    $('.profile-remove-button:not(.profile-remove-button-modal2)').on('click', function (e) {
      e.preventDefault();
      $('#remove_image').val('true');
      $('.profile-remove-button:not(.profile-remove-button-modal2)').css('display', 'none');
      $('#profile-upload').val('');
      $('#profile-avatar').attr(
        'src',
        'https://croucher.org.hk/assets/images/croucher-admin-1.png'
      );
    });

    // Preview selected modal2 profile image and prevent non-image uploads
    $(document).on('change', '#profile-upload-modal2', function (event) {
      var input = event.target;

      if (input.files && input.files[0]) {
        var file = input.files[0];
        var allowedTypes = ['image/jpeg', 'image/png'];
        var maxSize = 5 * 1024 * 1024; // 5MB

        if (allowedTypes.indexOf(file.type) === -1) {
          alert('Please select a JPG or PNG image only.');
          return;
        }

        if (file.size > maxSize) {
          alert('File size must not exceed 5MB.');
          $(this).val('');
          return;
        }

        var reader = new FileReader();

        reader.onload = function(e) {
          var base64Image = e.target.result;
          $('#profile-avatar-modal2').attr('src', base64Image);
          $('.profile-remove-button-modal2').css('display', 'block');
          $('#remove_image_modal2').val('false');

          var userUid = $('.profile-remove-button-modal2').data('user-uid');
          var uploadUrl = $('#modal2').data('upload-url');
          if (userUid && uploadUrl) {
            $.ajax({
              url: uploadUrl,
              type: 'PUT',
              contentType: 'application/json',
              data: JSON.stringify({ user: { image: base64Image } }),
              success: function(response) {
                var profileImage = response?.data?.attributes?.profile_image;
                if (profileImage) {
                  $('#profile-avatar-modal2').attr('src', profileImage);
                }
                console.log('Profile image uploaded successfully');
              },
              error: function(xhr) {
                var errorMessage = 'Failed to upload profile image.';
                try {
                  var response = JSON.parse(xhr.responseText);
                  if (response.error) {
                    errorMessage = Array.isArray(response.error) ? response.error.join('\n') : response.error;
                  }
                } catch (e) {}
                alert(errorMessage);
                console.error('Failed to upload profile image:', xhr.responseText);
              }
            });
          }
        };
        reader.readAsDataURL(file);
      }
    });

    $(document).on('click', '.profile-remove-button-modal2', function (e) {
      e.preventDefault();
      var removeUrl = $('#modal2').data('remove-url');
      $('#profile-upload-modal2').val('');
      $('#remove_image_modal2').val('true');
      $('.profile-remove-button-modal2').css('display', 'none');

      if (removeUrl) {
        $.ajax({
          url: removeUrl,
          type: 'GET',
          success: function(response) {
            var profileImage = response?.data?.attributes?.profile_image;
            if (profileImage) {
              $('#profile-avatar-modal2').attr('src', profileImage);
            }
            console.log('Profile image removed successfully');
          },
          error: function(xhr) {
            console.error('Failed to remove profile image:', xhr.responseText);
          }
        });
      }
    });

    $(document).on('click', '#password-toggle-btn-modal2', function () {
      $('#password-fields-modal2').toggleClass('expanded');
      $('#password-toggle-icon-modal2').toggleClass('expanded');
    });

    // Handle the password reset form the same way for click and Enter submits.
    $('form.edit_user.password').on('submit', function (e) {
      e.preventDefault();

      var $form = $(this);

      $.ajax({
        url: $form.attr('action'),
        type: 'POST',
        data: $form.serialize(),
      })
        .done(function (res, status, xhr) {
          $('#passwordModal').removeClass('modal-open');
          $('#passwordConfirmModal').addClass('modal-open');
        })
        .fail(function (xhr) {
          var errorMsg = xhr.responseJSON.error;
          $('#passwordModal').removeClass('modal-open');
          $('#passwordResetFailureModal').find('.alert-message').text(errorMsg);
          $('#passwordResetFailureModal').addClass('modal-open');
        });
    });
  });
}).call(this);

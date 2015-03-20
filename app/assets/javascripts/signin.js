

function onSignInCallback(authResult) {
        
        console.log(authResult);
        signInButton = document.getElementById('gConnect');
        loaderWrapper = $('.loader-wrapper');

        signInButton.style.display = 'none';

        if (authResult['error']) {
            console.log('There was an error: ' + authResult['error']);
            // The user is not signed in.
            //user_signed_out callback versus immeditate_fail
            if (authResult['error'] == "immediate_failed") {
                console.log('NO APP ACCESS')
                console.log(authResult['status'])
            }
            if (authResult['error'] == "user_signed_out") {
                console.log('SignedOut googleCallBack')
                console.log(authResult['status'])
                
                $('#signin-in-error-modal-body').empty();
                $('#modal-window-signin-error').modal('show');
                $('#signin-in-error-modal-body').append( 
                  '<p>' + 'User Signed Out :: Reload Page if you want to sign in' + '</p>' + 
                  '<a class="btn no-text-decoration" href="/signin/refresh_connection" >' + 'Refresh' + '</a>'
                );
                // catch for legacy signin..
                if (helper.authResult) {
                  helper.disconnectUser(false);
                } 
            }
            if (signInButton.style.display = 'none' ) {
               signInButton.style.display = 'block';
            }

        } else {

            if (verifyAccessToken(authResult)) {
                
                console.log('tokenverified..status is..')
                console.log(authResult['status'])
                
                verified_auth_tokens = authResult
                var disconnectButton = document.getElementById('disconnect');
      
                disconnectButton.addEventListener('click', function() {
                     helper.disconnectServer();
                });

                if (authResult['status']['signed_in'] && authResult['status']['google_logged_in'] ) {

                  console.log('auth signed_in and google_logged_in status')
                  gapi.client.load('plus','v1', JSProfileCallBack);

                } else {
                  helper.disconnectUser(false);
                }

            } else {

              console.log(authResult['status'])
              
              $('#signin-in-error-modal-body').empty();
              $('#modal-window-signin-error').modal('show');
              $('#signin-in-error-modal-body').append(
                  '<p>' + 'Browser Authentication Failed, you need to REFRESH your connection' +
                  '</p>' + 
                  '<p>' + 
                  'We check over 10 steps of authentication on signin, all of which are impacted by browser inactivity and state.' + 
                  '</p>' +
                  '<p>' + 'Please understand we do this for your utmost data and business protection and security' + '</p>' +
                  '<a class="btn btn-main-o" href="/signin/refresh_connection" ><i class="fa fa-exchange"></i>' + 'Refresh' + '</a>'
              );

              helper.disconnectUser(false);

            }
               
        }//End of ELSE[ERROR]

};//End of API console CallBack Reference

function verifyAccessToken(authResult) {
    
    var tokens_checked_and_safe = false

    $.ajax({

        type: 'GET',
        async: false,
        url: 'https://www.googleapis.com/oauth2/v1/tokeninfo?access_token=' + authResult.access_token,
        contentType: 'application/octet-stream; charset=utf-8',

        success: function(result) {
            if (!result.error) {
                helper.user_google_id = result.user_id;
                //for teamForms
                $('#circle_user_id').val(result.user_id)
                tokens_checked_and_safe = true
            }
        }//END of  SucceSS

    });//END OF AJAX
    return tokens_checked_and_safe
};  


function JSProfileCallBack() {
      var clientStateToken = $("#state").text();

      var route = window.location.href 
     
      var request = gapi.client.plus.people.get( {'userId' : 'me'} );
      
      request.execute( function(profile) {
              //Renders the authenticated user's Google+ profile.
              helper.appendProfile(profile);
              $('#user-email-address').html(profile.emails[0].value)
              //connects and verifies ServerSide client connection
              if (route.indexOf("circle") > -1) {
                  $('.loader-wrapper').show();
                  teamHelper.onSignInCallback(verified_auth_tokens);
                  teamHelper.user_google_id = profile.id;
                  $('#circle_user_id').val(profile.id);
              } else {
                  $('.loader-wrapper').show();
                  helper.setAuth(verified_auth_tokens);
                  helper.connectServerSide(clientStateToken);
                  foodHelper.loadLandingFeeds();
              }
      });//End of requestExecute
};//end of CallBack



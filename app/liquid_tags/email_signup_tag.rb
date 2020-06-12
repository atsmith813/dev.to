class EmailSignupTag < LiquidTagBase
  PARTIAL = "liquids/email_signup".freeze

  SCRIPT = <<~JAVASCRIPT.freeze
    var signupBtn = document.getElementById('email-signup-btn');

    signupBtn.addEventListener('click', function(e) {
      if (document.head.querySelector('meta[name="user-signed-in"][content="true"]')) {
        function handleSuccess(response) {
          console.log("(Email signup success) " + response);
          var statusEl = document.getElementById('email-signup-status');
          statusEl.style.color = "green";
          statusEl.innerHTML = "Thanks for subscribing!";
        }

        function handleError(response) {
          var errorMsg = prettifyError(response.error);
          console.error("(Email signup error) " +  errorMsg);
          var statusEl = document.getElementById('email-signup-status');
          statusEl.style.color = "red";
          statusEl.innerHTML = errorMsg;
        }

        function prettifyError(errorMsg) {
          if (errorMsg == "Subscriber has already been taken") {
            return "You've already subscribed to this!"
          } else {
            return errorMsg
          }
        }

        var tokenMeta = document.querySelector("meta[name='csrf-token']");

        if (!tokenMeta) {
          alert('Whoops. There was an error. Your vote was not counted. Try refreshing the page.')
          return
        }

        var csrfToken = tokenMeta.getAttribute('content');
        var articleId = document.getElementById('article-body').dataset.articleId;

        window.fetch('/email_signups', {
          method: 'POST',
          headers: {
            'X-CSRF-Token': csrfToken,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(
            {
              email_signup: {
                source_type: "Article",
                source_id: articleId
              }
            }
          ),
          credentials: 'same-origin',
        }).then(function(response) {
          if (response.ok) {
            response.json().then(function(j){handleSuccess(j)});
          } else {
            response.json().then(function(j){handleError(j)});
          }
        })
      } else {
        if (typeof showModal !== "undefined") {
          showModal('email_signup');
        }
      }
    });
  JAVASCRIPT

  def initialize(_tag_name, cta_text, _tokens)
    @cta_text = cta_text.strip
  end

  def render(_context)
    ActionController::Base.new.render_to_string(
      partial: PARTIAL,
      locals: {
        cta_text: @cta_text
      },
    )
  end

  def self.script
    SCRIPT
  end
end

Liquid::Template.register_tag("email_signup", EmailSignupTag)

class EmailSignupTag < LiquidTagBase
  PARTIAL = "liquids/email_signup".freeze

  SCRIPT = <<~JAVASCRIPT.freeze
    var signupBtn = document.getElementById('email-signup-btn');

    signupBtn.addEventListener('click', function(e) {
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
      }).then(function(response){
        console.log(response);
      })
    });
  JAVASCRIPT

  def initialize(_tag_name, cta_text, _tokens)
    @cta_text = cta_text
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

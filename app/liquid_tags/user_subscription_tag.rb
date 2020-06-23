class UserSubscriptionTag < LiquidTagBase
  PARTIAL = "liquids/user_subscription".freeze

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
end

Liquid::Template.register_tag("user_subscription", UserSubscriptionTag)

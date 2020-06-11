class EmailSignupTag < LiquidTagBase
  PARTIAL = "liquids/email_signup".freeze

  def initialize(_tag_name, cta_text, _tokens); end

  def render(context); end
end

Liquid::Template.register_tag("email_signup", EmailSignupTag)

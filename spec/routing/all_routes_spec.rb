require "rails_helper"

RSpec.describe "all routes", type: :routing do
  let(:podcast)     { create(:podcast) }
  let(:user)        { create(:user) }

  it "renders a podcast index if there is a podcast with the slug successfully" do
    expect(get: "/#{podcast.slug}").to route_to(
      locale: nil,
      controller: "stories",
      action: "index",
      username: podcast.slug,
    )
  end

  it "renders a user index if there is a user with the username successfully" do
    expect(get: "/#{user.username}").to route_to(
      locale: nil,
      controller: "stories",
      action: "index",
      username: user.username,
    )
  end

  it "renders a user's story successfully" do
    expect(get: "/ben/this-is-a-slug").to route_to(
      locale: nil,
      controller: "stories",
      action: "show",
      slug: "this-is-a-slug",
      username: "ben",
    )
  end

  context "when redirected routes" do
    include RSpec::Rails::RequestExampleGroup

    it "redirects /shop to the default shop_url" do
      # TODO: the hardcoded shop url needs to be removed from the routes in favor of a dynamic one.
      allow(SiteConfig).to receive(:shop_url).and_return("https://shop.dev.to")
      get shop_path

      expect(response).to redirect_to(SiteConfig.shop_url)
    end
  end
end

require "rails_helper"

RSpec.describe Redirects::ArticleHandler, type: :service do
  describe "::call" do
    it "creates a PathRedirect with a relevant article" do
      old_article = create(:article, title: "Ruby rocks!")
      new_article = create(:article, title: "Ruby on Rails rocks!")
      articles = [old_article, new_article]
      index_documents_for_search_class(articles, Search::FeedContent)

      expect { described_class.call(old_article.path) }.to change(PathRedirect, :count).by(1)
      expect(PathRedirect.last.old_path).to eq old_article.path
      expect(PathRedirect.last.new_path).to eq new_article.path
      expect(PathRedirect.last.source).to eq "service"
    end

    it "creates a PathRedirect with a relevant tag when no relevant article is found" do
      old_article = create(:article, title: "Ruby rocks!")
      index_documents_for_search_class([old_article], Search::FeedContent)

      tag = create(:tag, name: "ruby")
      index_documents_for_search_class([tag], Search::Tag)

      expect { described_class.call(old_article.path) }.to change(PathRedirect, :count).by(1)
      expect(PathRedirect.last.old_path).to eq old_article.path
      expect(PathRedirect.last.new_path).to eq "/t/#{tag.name}"
      expect(PathRedirect.last.source).to eq "service"
    end

    # TODO: Fix this
    xit "updates newly invalid path redirects" do
      old_article = create(:article, title: "Ruby rocks!")
      stale_path_article = create(:article, title: "Some stale Ruby title")
      new_article = create(:article, title: "Ruby on Rails rocks!")
      articles = [old_article, new_article]
      index_documents_for_search_class(articles, Search::FeedContent)

      create(:path_redirect, old_path: old_article.path, new_path: stale_path_article.path, source: "service")

      expect { described_class.call(stale_path_article.path) }.to change(PathRedirect, :count).by(0)
      expect(PathRedirect.last.old_path).to eq old_article.path
      expect(PathRedirect.last.new_path).to eq new_article.path
      expect(PathRedirect.last.source).to eq "service"
    end

    it "does nothing if a redirect already exists" do
      allow(DatadogStatsClient).to receive(:increment)
      article = create(:article, title: "Ruby rocks!")
      create(:path_redirect, old_path: article.path, new_path: "username/new-path", source: "service")
      described_class.call(article.path)

      expect(DatadogStatsClient).not_to have_received(:increment)
    end

    it "logs to Datadog when new_path is found" do
      allow(DatadogStatsClient).to receive(:increment)
      old_article = create(:article, title: "Ruby rocks!")
      new_article = create(:article, title: "Ruby on Rails rocks!")
      articles = [old_article, new_article]
      index_documents_for_search_class(articles, Search::FeedContent)
      described_class.call(old_article.path)

      tags = hash_including(tags: array_including("type:article", "old_path:#{old_article.path}", "status:found", "new_path:#{new_article.path}"))

      expect(DatadogStatsClient).to have_received(:increment).with("redirect_service", tags)
    end

    it "logs to Datadog when new_path is not found" do
      allow(DatadogStatsClient).to receive(:increment)
      old_article = create(:article, title: "Ruby rocks!")
      described_class.call(old_article.path)

      tags = hash_including(tags: array_including("type:article", "old_path:#{old_article.path}", "status:not_found"))

      expect(DatadogStatsClient).to have_received(:increment).with("redirect_service", tags)
    end
  end
end

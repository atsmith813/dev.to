module Redirects
  class Article
    def self.call(*args)
      new(*args).call
    end

    attr_reader :old_path

    def initialize(old_path)
      @old_path = old_path
    end

    def call
      # Don't do anything if a redirect already exists to make this idempotent
      return if PathRedirect.find_by(old_path: old_path)

      new_path = determine_new_path

      if new_path
        update_path_redirects(new_path)

        tags = ["type:article", "old_path:#{old_path}", "new_path:#{new_path}"]
      else
        tags = ["type:article", "old_path:#{old_path}"]
      end

      # Log result to Datadog
      DatadogStatsClient.increment("redirect_service", tags: tags)
    end

    private

    def update_path_redirects(new_path)
      # Update newly invalid path_redirects
      invalid_path_redirects = PathRedirect.where(new_path: old_path)
      invalid_path_redirects.update_all(new_path: new_path, source: "service")

      # Create the new redirect
      PathRedirect.create(old_path: old_path, new_path: new_path, source: "service")
    end

    def determine_new_path
      releveant_article_path = find_relevant_article_path
      return releveant_article_path if releveant_article_path

      find_relevant_tag_path
    end

    def search_fields
      # Determine the slug from the Article's path, commonly "/#{username}/#{slug}"
      slug = old_path.split("/").last

      # An Article's slug is built as follows in the title_to_slug method on the Article
      # model:
      #
      # title.to_s.downcase.parameterize.tr("_", "") + "-" + rand(100_000).to_s(26)
      #
      # We "reverse" that with split("-") and [0...-1] is to get rid of the
      # last Array element which is that random number.
      slug.split("-")[0...-1]
    end

    def find_relevant_article_path
      results = Search::FeedContent.search_documents(params: article_search_params)

      # There's a race condition here where the unpublished Article hasn't been
      # removed from Elasticsearch when we come here to search for a
      # replacement, so it's possible one of the results is "itself". This
      # makes sure we don't choose that Article.
      result = results.detect { |article| article["path"] != old_path }
      result ? result["path"] : nil
    end

    def article_search_params
      {
        search_fields: search_fields.join(" "),
        class_name: "Article",
        per_page: 2,
        page: 0
      }
    end

    def find_relevant_tag_path
      result = Search::Tag.search_documents(tag_query_string).first
      result ? "t/#{result['name']}" : nil
    end

    def tag_query_string
      "name:(#{search_fields.join(' OR ')}) AND supported:true"
    end
  end
end

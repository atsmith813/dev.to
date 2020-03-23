# This worker checks the number of records for each Elasticsearch index and
# compares it to the number of records in our database.
#
# For indexes that don't match a single model we need to implement a custom
# model_count method on the Search class to do the counts for us
module Metrics
  class RecordDbAndEsRecordCountsWorker
    include Sidekiq::Worker

    sidekiq_options queue: :low_priority, retry: 10

    # Adjustable margin of error - this is how far off the index count can be
    # from the database count before we raise an error
    def perform(margin_of_error = 0)
      Search::Cluster::SEARCH_CLASSES.each do |search_class|
        db_count = db_count(search_class)
        index_count = Search::Client.count(index: search_class::INDEX_ALIAS).dig("count")
        record_difference = (db_count - index_count).abs

        tags = {
          search_class: search_class,
          db_count: db_count,
          index_count: index_count,
          record_difference: record_difference,
          margin_of_error: margin_of_error,
          action: "record_count"
        }

        tags[:record_count] = if record_difference > margin_of_error
                                "mismatch"
                              else
                                "match"
                              end

        DatadogStatsClient.increment("elasticsearch", tags: tags)
      end
    end

    private

    def db_count(search_class)
      model = search_class.class_name.safe_constantize

      return model.count if model.respond_to?(:count)

      raise "model_count method not implemented for #{search_class}!" unless search_class.respond_to? :model_count

      search_class.model_count
    end
  end
end

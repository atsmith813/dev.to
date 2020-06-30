module UserSubscriptions
  # This is for all the logic and error handling when creating a
  # UserSubscription from the UserSubscriptionsController.
  class Create
    attr_accessor :user, :source_type, :source_id, :source, :response

    def self.call(*args)
      new(*args).call
    end

    def initialize(user, user_subscription_params)
      @user = user
      @source_type = user_subscription_params[:source_type]
      @source_id = user_subscription_params[:source_id]
      @response = Struct.new(success: false, data: nil, error: nil)

      # TODO: [@thepracticaldev/delightful]: uncomment this once email confirmation is re-enabled
      # @subscriber_email = user_subscription_params[:subscriber_email]
    end

    # Returns a Struct with
    #   success: boolean - true if creating a UserSubscription was successful
    #   data: UserSubscription - the created record, if successful
    #   error: string - error message, if unsuccessful
    def call
      response.error = "source_id is required" unless source_id
      return response if response.error

      response.error = "source_type is required" unless source_type
      return response if response.error

      # TODO: [@thepracticaldev/delightful]: uncomment this once email confirmation is re-enabled
      # response.error = "subscriber_email is required" unless subscriber_email
      # return response if response.error

      # TODO: [@thepracticaldev/delightful]: uncomment this once email confirmation is re-enabled
      # response.error = "Subscriber email mismatch." if subscriber_email_stale?
      # return response if response.error

      response.error = "You can't subscribe with an Apple private relay email. Please update your email address and try again." if subscriber_authed_with_apple?
      return response if response.error

      response.error = "Invalid source_type." unless UserSubscription::ALLOWED_TYPES.include?(source_type)
      return response if response.error

      source = source_type.constantize.find_by(id: source_id)

      response.error = "Source not found." unless active_source?(source)
      return response if response.error

      response.error = "User subscriptions aren't enabled for the requested source." unless user_subscription_tag_enabled?(source)
      return response if response.error

      user_subscription = source.build_user_subscription(user)

      if user_subscription.save
        response.success = true
        response.data = user_subscription
      else
        response.error = user_subscription.errors.full_messages.to_sentence
      end

      response
    end

    private

    def active_source?(source)
      return false unless source

      # Don't create new user subscriptions for inactive sources
      # (i.e. unpublished Articles, deleted Comments, etc.)
      case source_type
      when "Article"
        source.published?
      else
        false
      end
    end

    def user_subscription_tag_enabled?(source)
      liquid_tags =
        case source_type
        when "Article"
          source.liquid_tags_used(:body)
        else
          source.liquid_tags_used
        end

      liquid_tags.include?(UserSubscriptionTag)
    end

    def subscriber_authed_with_apple?
      user.email.end_with?("@privaterelay.appleid.com")
    end

    # This checks if the email address the user saw/consented to share is the
    # same as their current email address. A mismatch occurs if a user updates
    # their email address in a new/separate tab and then tries to subscribe on
    # the old/stale tab without refreshing. In that case, the user would have
    # consented to share their old email address instead of the current one.
    def subscriber_email_stale?
      user&.email != subscriber_email
    end
  end
end

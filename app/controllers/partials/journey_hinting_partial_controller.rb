# Shared methods for controllers which use the journey hint cookie to give users IDP suggestions
module JourneyHintingPartialController
  PENDING_STATUS = 'PENDING'.freeze

  def journey_hint_value
    MultiJson.load(cookies.encrypted[CookieNames::VERIFY_FRONT_JOURNEY_HINT])
  rescue MultiJson::ParseError
    nil
  end

  def attempted_entity_id
    journey_hint_value.nil? ? nil : journey_hint_value['ATTEMPT']
  end

  def success_entity_id
    journey_hint_value.nil? ? nil : journey_hint_value['SUCCESS']
  end

  def last_status
    journey_hint = journey_hint_value
    journey_hint.nil? ? nil : journey_hint['STATE']
  end

  def is_last_status?(status)
    last_status_value = last_status
    !last_status_value.nil? && last_status_value['STATUS'] == status
  end

  def last_idp
    last_status_value = last_status
    last_status_value.nil? ? nil : last_status_value.fetch('IDP', nil)
  end

  def last_rp
    last_status_value = last_status
    last_status_value.nil? ? nil : last_status_value.fetch('RP', nil)
  end

  def user_followed_journey_hint(entity_id_followed_by_user)
    hinted_id = success_entity_id
    !hinted_id.nil? && hinted_id == entity_id_followed_by_user
  end

  def retrieve_decorated_singleton_idp_array_by_entity_id(providers, entity_id)
    IDENTITY_PROVIDER_DISPLAY_DECORATOR.decorate_collection(providers.select { |idp| idp.entity_id == entity_id })
  end
end

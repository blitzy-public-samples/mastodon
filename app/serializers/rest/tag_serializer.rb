# frozen_string_literal: true

class REST::TagSerializer < ActiveModel::Serializer
  include RoutingHelper

  attributes :id, :name, :url, :history

  attribute :following, if: :current_user?
  attribute :featuring, if: :current_user?

  # Local vs. Federated Trend Comparison: expose origin-scoped history when a scope is requested
  attribute :history_local, if: :scoped?
  attribute :history_remote, if: :scoped?

  def id
    object.id.to_s
  end

  def url
    tag_url(object)
  end

  def name
    object.display_name
  end

  def following
    if instance_options && instance_options[:relationships]
      instance_options[:relationships].following_map[object.id] || false
    else
      TagFollow.exists?(tag_id: object.id, account_id: current_user.account_id)
    end
  end

  def featuring
    if instance_options && instance_options[:relationships]
      instance_options[:relationships].featuring_map[object.id] || false
    else
      FeaturedTag.exists?(tag_id: object.id, account_id: current_user.account_id)
    end
  end

  def current_user?
    !current_user.nil?
  end

  # Local vs. Federated Trend Comparison:
  # Gate the scoped attributes on a DEDICATED, NON-RESERVED instance option (:trend_scope),
  # passed by the controller exactly as :relationships is passed. It intentionally does NOT reuse
  # the :scope option key: ActiveModelSerializers 0.10 reserves :scope for the serialization scope,
  # and since scope_name defaults to :current_user the serializer's current_user resolves to that
  # scope. Keying on :scope therefore breaks the non-negotiable byte-for-byte no-scope contract
  # (AAP 0.6.1 / R13): for an AUTHENTICATED no-scope request the controller would pass scope: nil,
  # and AMS get_serializer does `serialization_scope ||= options.fetch(:scope) { current_user }` --
  # because the :scope key is present with a nil value, fetch returns that nil (the block is only
  # run when the key is ABSENT), clobbering current_user to nil and dropping following/featuring;
  # conversely an anonymous scope=all request would set current_user to the string "all" and wrongly
  # emit following/featuring. A non-reserved key is the only zero-regression design (empirically
  # verified via authenticated request specs below). The controller passes trend_scope: scope_param.
  def scoped?
    instance_options && instance_options[:trend_scope].present?
  end

  # Local vs. Federated Trend Comparison:
  def history_local
    Trends::ScopedHistory.new('tags', object.id, :local).as_json
  end

  # Local vs. Federated Trend Comparison:
  def history_remote
    Trends::ScopedHistory.new('tags', object.id, :remote).as_json
  end
end

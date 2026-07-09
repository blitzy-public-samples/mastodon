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
  # NOTE: use a dedicated, non-reserved instance option (:trend_scope). ActiveModelSerializers
  # reserves :scope for the serialization scope (current_user), so keying on :scope would emit
  # history_local/history_remote on every authenticated request and break the byte-for-byte
  # no-scope response contract. The controller passes trend_scope: <validated params[:scope]>.
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

# frozen_string_literal: true

class Api::V1::Trends::TagsController < Api::BaseController
  include DeprecationConcern

  before_action :set_tags

  after_action :insert_pagination_headers

  DEFAULT_TAGS_LIMIT = 10

  deprecate_api '2022-03-30', only: :index, if: -> { request.path == '/api/v1/trends' }

  def index
    cache_if_unauthenticated!
    # Local vs. Federated Trend Comparison: forward the optional, validated scope to the serializer as a
    # DEDICATED, NON-RESERVED instance option (passed exactly as :relationships is). It is NOT keyed as
    # :scope on purpose: ActiveModelSerializers 0.10 reserves :scope for the serialization scope (which,
    # via scope_name: :current_user, backs the serializer's current_user), so keying on :scope would break
    # the non-negotiable byte-for-byte no-scope contract (AAP 0.6.1 / R13) -- passing scope: nil on a
    # no-scope request clobbers an authenticated current_user to nil (dropping following/featuring), and
    # scope=all would wrongly surface following/featuring for anonymous requests. :trend_scope avoids both,
    # matching REST::TagSerializer#scoped? (see that file's note; verified by the authenticated request specs).
    render json: @tags, each_serializer: REST::TagSerializer, relationships: TagRelationshipsPresenter.new(@tags, current_user&.account_id), trend_scope: scope_param
  end

  private

  def enabled?
    Setting.trends
  end

  def set_tags
    @tags = if enabled?
              tags_from_trends.offset(offset_param).limit(limit_param(DEFAULT_TAGS_LIMIT))
            else
              []
            end
  end

  def tags_from_trends
    scope = Trends.tags.query.allowed.in_locale(content_locale)
    scope = scope.filtered_for(current_account) if user_signed_in?
    scope
  end

  def next_path
    api_v1_trends_tags_url pagination_params(offset: offset_param + limit_param(DEFAULT_TAGS_LIMIT)) if records_continue?
  end

  def prev_path
    api_v1_trends_tags_url pagination_params(offset: offset_param - limit_param(DEFAULT_TAGS_LIMIT)) if offset_param > limit_param(DEFAULT_TAGS_LIMIT)
  end

  def offset_param
    params[:offset].to_i
  end

  # Local vs. Federated Trend Comparison: validate the optional scope param; nil (no scope) otherwise
  def scope_param
    params[:scope].presence_in(%w(local remote all))
  end

  def records_continue?
    @tags.size == limit_param(DEFAULT_TAGS_LIMIT)
  end
end

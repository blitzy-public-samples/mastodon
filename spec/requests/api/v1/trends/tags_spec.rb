# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API V1 Trends Tags' do
  describe 'GET /api/v1/trends/tags' do
    context 'when trends are disabled' do
      before { Setting.trends = false }

      it 'returns http success' do
        get '/api/v1/trends/tags'

        expect(response)
          .to have_http_status(200)
          .and not_have_http_link_header
        expect(response.content_type)
          .to start_with('application/json')
        expect(response.headers['Deprecation'])
          .to be_nil
      end
    end

    context 'when trends are enabled' do
      before { Setting.trends = true }

      it 'returns http success' do
        prepare_trends
        stub_const('Api::V1::Trends::TagsController::DEFAULT_TAGS_LIMIT', 2)
        get '/api/v1/trends/tags'

        expect(response)
          .to have_http_status(200)
          .and have_http_link_header(api_v1_trends_tags_url(offset: 2)).for(rel: 'next')
        expect(response.content_type)
          .to start_with('application/json')
        expect(response.headers['Deprecation'])
          .to be_nil
      end

      def prepare_trends
        Fabricate.times(3, :tag, trendable: true).each do |tag|
          2.times { |i| Trends.tags.add(tag, i) }
        end
        Trends::Tags.new(threshold: 1).refresh
      end

      # Local vs. Federated Trend Comparison: optional scope parameter
      context 'with the scope parameter' do
        before { prepare_trends }

        it 'keeps the response schema unchanged when no scope is given' do
          get '/api/v1/trends/tags'

          expect(response).to have_http_status(200)
          expect(response.parsed_body).to_not be_empty
          response.parsed_body.each do |tag|
            expect(tag.keys).to include('id', 'name', 'url', 'history')
            expect(tag.keys).to_not include('history_local')
            expect(tag.keys).to_not include('history_remote')
          end
        end

        it 'exposes history_local and history_remote when scope=all' do
          get '/api/v1/trends/tags', params: { scope: 'all' }

          expect(response).to have_http_status(200)
          expect(response.parsed_body).to_not be_empty
          response.parsed_body.each do |tag|
            expect(tag.keys).to include('history_local', 'history_remote')
            expect(tag['history_local'].length).to eq(tag['history'].length)
            expect(tag['history_remote'].length).to eq(tag['history'].length)
            expect(tag['history_local'].first.keys).to match_array(tag['history'].first.keys)
          end
        end

        it 'ignores an invalid scope value' do
          get '/api/v1/trends/tags', params: { scope: 'bogus' }

          expect(response).to have_http_status(200)
          response.parsed_body.each do |tag|
            expect(tag.keys).to_not include('history_local')
            expect(tag.keys).to_not include('history_remote')
          end
        end
      end

      # Local vs. Federated Trend Comparison: the scope option must NOT be keyed on the AMS-reserved
      # :scope (which backs the serializer's current_user); these authenticated cases guard the
      # non-negotiable byte-for-byte no-scope contract for signed-in users (following/featuring stay
      # present, scoped fields stay absent) and confirm scope=all layers the scoped fields on top.
      context 'with the scope parameter when authenticated' do
        include_context 'with API authentication', oauth_scopes: 'read'

        before { prepare_trends }

        it 'keeps the authenticated no-scope response unchanged (following/featuring present, scoped fields absent)' do
          get '/api/v1/trends/tags', headers: headers

          expect(response).to have_http_status(200)
          expect(response.parsed_body).to_not be_empty
          response.parsed_body.each do |tag|
            expect(tag.keys).to include('id', 'name', 'url', 'history', 'following', 'featuring')
            expect(tag.keys).to_not include('history_local')
            expect(tag.keys).to_not include('history_remote')
          end
        end

        it 'layers history_local and history_remote onto the authenticated response when scope=all' do
          get '/api/v1/trends/tags', headers: headers, params: { scope: 'all' }

          expect(response).to have_http_status(200)
          expect(response.parsed_body).to_not be_empty
          response.parsed_body.each do |tag|
            expect(tag.keys).to include('history_local', 'history_remote', 'following', 'featuring')
            expect(tag['history_local'].length).to eq(tag['history'].length)
            expect(tag['history_remote'].length).to eq(tag['history'].length)
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Trends::ScopedHistory do
  let!(:at_time) { DateTime.new(2021, 11, 14, 10, 15, 0) }
  let(:tag) { Fabricate(:tag) }
  let(:local_history) { described_class.new('tags', tag.id, :local) }
  let(:remote_history) { described_class.new('tags', tag.id, :remote) }

  describe 'key naming' do
    it 'uses origin-suffixed uses and accounts keys for local' do
      day = local_history.get(at_time)
      expect(day.key_for(:uses)).to eq("activity:tags:#{tag.id}:#{at_time.beginning_of_day.to_i}:local")
      expect(day.key_for(:accounts)).to eq("activity:tags:#{tag.id}:#{at_time.beginning_of_day.to_i}:local:accounts")
    end

    it 'uses a distinct key for remote' do
      day = remote_history.get(at_time)
      expect(day.key_for(:uses)).to eq("activity:tags:#{tag.id}:#{at_time.beginning_of_day.to_i}:remote")
      expect(day.key_for(:accounts)).to eq("activity:tags:#{tag.id}:#{at_time.beginning_of_day.to_i}:remote:accounts")
    end
  end

  describe '#add' do
    before { local_history.add(1, at_time) }

    it 'increments only the local scoped history' do
      expect(local_history.get(at_time).uses).to eq 1
      expect(local_history.get(at_time).accounts).to eq 1
    end

    it 'does not touch the remote scoped history' do
      expect(remote_history.get(at_time).uses).to eq 0
      expect(remote_history.get(at_time).accounts).to eq 0
    end

    it 'does not touch the existing combined history keys' do
      expect(tag.history.get(at_time).uses).to eq 0
      expect(tag.history.get(at_time).accounts).to eq 0
    end
  end

  describe 'independence of the two origins' do
    before do
      local_history.add(1, at_time)
      local_history.add(2, at_time)
      remote_history.add(3, at_time)
    end

    it 'keeps per-origin counts independent' do
      expect(local_history.get(at_time).uses).to eq 2
      expect(local_history.get(at_time).accounts).to eq 2
      expect(remote_history.get(at_time).uses).to eq 1
      expect(remote_history.get(at_time).accounts).to eq 1
    end
  end

  describe '#as_json zero-fill and length parity' do
    it 'matches the combined history length (7 buckets)' do
      expect(local_history.as_json.length).to eq(tag.history.as_json.length)
      expect(local_history.as_json.length).to eq 7
    end

    it 'zero-fills absent buckets with the correct shape' do
      local_history.as_json.each do |bucket|
        expect(bucket.keys).to match_array(%i(day accounts uses))
        expect(bucket[:uses]).to eq '0'
        expect(bucket[:accounts]).to eq '0'
      end
    end
  end

  describe 'expiry parity with the combined history' do
    before { local_history.add(1, at_time) }

    it 'expires scoped buckets on the same 14-day horizon' do
      day = local_history.get(at_time)
      expect(redis.ttl(day.key_for(:uses))).to be_within(5).of(14.days.to_i)
      expect(redis.ttl(day.key_for(:accounts))).to be_within(5).of(14.days.to_i)
    end
  end
end

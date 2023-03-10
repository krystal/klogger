# frozen_string_literal: true

require 'spec_helper'
require 'klogger/logger'

module Klogger

  RSpec.describe GroupSet do
    subject(:group_set) { described_class.new }

    describe '#add' do
      it 'adds a group' do
        group_set.add(foo: 'bar')
        expect(group_set.groups.first).to match hash_including(id: match(/\A[a-f0-9]{8}\z/), tags: { foo: 'bar' })
      end

      it 'returns the group id' do
        expect(group_set.add(foo: 'bar')).to match(/\A[a-f0-9]{8}\z/)
      end
    end

    describe '#pop' do
      it 'removes the last group' do
        group_set.add(foo: 'bar')
        group_set.pop
        expect(group_set.groups).to be_empty
      end
    end

    describe '#call' do
      it 'creates a group, calls the block and then pops it' do
        group_set.call(foo: 'bar') do
          expect(group_set.groups.first).to match hash_including(id: match(/\A[a-f0-9]{8}\z/), tags: { foo: 'bar' })
        end
        expect(group_set.groups).to be_empty
      end
    end

    describe '#call_without_id' do
      it 'creates a group, calls the block and then pops it' do
        group_set.call_without_id(foo: 'bar') do
          expect(group_set.groups.first).to match hash_including(id: nil, tags: { foo: 'bar' })
        end
        expect(group_set.groups).to be_empty
      end
    end
  end

end

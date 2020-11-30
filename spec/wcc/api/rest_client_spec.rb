# frozen_string_literal: true

require 'spec_helper'
require 'wcc/api/rest_client'

RSpec.describe WCC::API::RestClient do
  describe 'initialize' do
    after do
      described_class::ADAPTERS = {
        typhoeus: ['typhoeus', '~> 1.0'],
        http: ['http', '> 1.0', '< 3.0']
      }.freeze
    end

    it 'fails to load when no adapter gem found' do
      expect do
        described_class::ADAPTERS = {
          asdf: ['asdf', '~> 1.0']
        }.freeze

        described_class.new(
          api_url: 'https://cdn.contentful.com'
        )
      end.to raise_error(ArgumentError)
    end

    it 'fails to load when gem is wrong version' do
      expect do
        described_class::ADAPTERS = {
          http: ['http', '< 1.0']
        }.freeze

        described_class.new(
          api_url: 'https://cdn.contentful.com'
        )
      end.to raise_error(ArgumentError)
    end

    it 'fails to load when adapter is not invokeable' do
      described_class::ADAPTERS = {}.freeze

      expect do
        described_class::ADAPTERS = {
          http: ['http', '< 1.0']
        }.freeze

        described_class.new(
          api_url: 'https://cdn.contentful.com',
          adapter: :whoopsie
        )
      end.to raise_error(ArgumentError)
    end
  end

  described_class::ADAPTERS.keys.each do |adapter|
    context "with #{adapter} adapter" do
      subject(:client) do
        described_class.new(
          api_url: 'https://cdn.contentful.com/spaces/1234',
          adapter: adapter
        )
      end

      let(:entries) do
        ::JSON.parse(load_fixture('contentful/entries.json'))
      end

      describe 'get' do
        it 'gets entries with query params' do
          stub_request(:get, 'https://cdn.contentful.com/spaces/1234/entries?limit=2')
            .to_return(body: load_fixture('contentful/entries.json'))

          # act
          resp = client.get('entries', limit: 2)

          # assert
          resp.assert_ok!
          expect(resp.code).to eq(200)
          expect(resp.to_json['items'].map { |i| i.dig('sys', 'id') }).to eq(
            %w[6xJzDTX2HCo0u4QKIuGCOu 5yozzvgItUSYu4eI8yQ0ee]
          )
        end

        it 'can query entries with query param' do
          stub_request(:get, 'https://cdn.contentful.com/spaces/1234/entries')
            .with(query: {
              'content_type' => 'menuButton',
              'fields.text' => 'Ministries'
            })
            .to_return(body: load_fixture('contentful/entries.json'))

          # act
          resp = client.get('entries',
                            content_type: 'menuButton',
                            'fields.text' => 'Ministries')

          # assert
          resp.assert_ok!
          expect(resp.code).to eq(200)
          expect(resp.to_json['items'].map { |i| i.dig('sys', 'id') }).to eq(
            %w[6xJzDTX2HCo0u4QKIuGCOu 5yozzvgItUSYu4eI8yQ0ee]
          )
        end

        it 'follows redirects' do
          stub_request(:get, 'http://jtj.watermark.org/api')
            .to_return(status: 301, headers: { 'Location' => 'https://jtj.watermark.org/api' })
          stub_request(:get, 'https://jtj.watermark.org/api')
            .to_return(body: '{ "links": { "entries": "/entries" } }')

          client = described_class.new(
            api_url: 'http://jtj.watermark.org/'
          )

          # act
          resp = client.get('/api')

          # assert
          resp.assert_ok!
          expect(resp.to_json['links']).to_not be_nil
        end

        it 'paginates directly when block given' do
          page1 = entries.merge('total' => 7)
          page2 = entries.merge('total' => 7, 'skip' => 2)
          page3 = entries.merge('total' => 7, 'skip' => 4)
          page4 = entries.merge('total' => 7, 'skip' => 6)
          stub_request(:get, 'https://cdn.contentful.com/spaces/1234/entries')
            .with(query: { 'limit' => 2 })
            .to_return(body: page1.to_json)
          stub_request(:get, 'https://cdn.contentful.com/spaces/1234/entries')
            .with(query: { 'limit' => 2, 'skip' => 2 })
            .to_return(body: page2.to_json)
          stub_request(:get, 'https://cdn.contentful.com/spaces/1234/entries')
            .with(query: { 'limit' => 2, 'skip' => 4 })
            .to_return(body: page3.to_json)
          stub_request(:get, 'https://cdn.contentful.com/spaces/1234/entries')
            .with(query: { 'limit' => 2, 'skip' => 6 })
            .to_return(body: page4.to_json)

          # act
          resp = client.get('entries', limit: 2)

          # assert
          resp.assert_ok!
          num_pages = 0
          resp.each_page do |page|
            expect(page.to_json['items'].length).to be <= 2
            num_pages += 1
          end
          expect(num_pages).to eq(4)
        end

        it 'does lazy pagination' do
          page1 = entries.merge('total' => 7)
          page2 = entries.merge('total' => 7, 'skip' => 2)
          page3 = entries.merge('total' => 7, 'skip' => 4)
          page4 = entries.merge('total' => 7, 'skip' => 6, 'items' => [entries['items'][0]])
          stub_request(:get, 'https://cdn.contentful.com/spaces/1234/entries')
            .with(query: { 'limit' => 2 })
            .to_return(body: page1.to_json)
          stub_request(:get, 'https://cdn.contentful.com/spaces/1234/entries')
            .with(query: { 'limit' => 2, 'skip' => 2 })
            .to_return(body: page2.to_json)
          stub_request(:get, 'https://cdn.contentful.com/spaces/1234/entries')
            .with(query: { 'limit' => 2, 'skip' => 4 })
            .to_return(body: page3.to_json)
          stub_request(:get, 'https://cdn.contentful.com/spaces/1234/entries')
            .with(query: { 'limit' => 2, 'skip' => 6 })
            .to_return(body: page4.to_json)

          # act
          resp = client.get('entries', limit: 2)

          # assert
          resp.assert_ok!
          pages = resp.each_page
          expect(pages).to be_a(Enumerator::Lazy)
          pages =
            pages.map do |page|
              expect(page.to_json['items'].length).to be <= 2
              page.to_json['items']
            end
          pages = pages.force
          expect(pages.length).to eq(4)
          expect(pages.flatten.map { |c| c.dig('sys', 'id') })
            .to eq(%w[
                     6xJzDTX2HCo0u4QKIuGCOu
                     5yozzvgItUSYu4eI8yQ0ee
                     6xJzDTX2HCo0u4QKIuGCOu
                     5yozzvgItUSYu4eI8yQ0ee
                     6xJzDTX2HCo0u4QKIuGCOu
                     5yozzvgItUSYu4eI8yQ0ee
                     6xJzDTX2HCo0u4QKIuGCOu
                   ])
        end

        it 'does not paginate if only the first page is taken' do
          stub_request(:get, 'https://cdn.contentful.com/spaces/1234/entries')
            .with(query: { 'limit' => 2 })
            .to_return(body: load_fixture('contentful/entries.json'))

          stub_request(:get, 'https://cdn.contentful.com/spaces/1234/entries')
            .with(query: { 'limit' => 2, 'skip' => 2 })
            .to_raise(StandardError.new('Should not execute request for second page'))

          # act
          resp = client.get('entries', limit: 2)

          # assert
          resp.assert_ok!
          items = resp.items.take(2)
          expect(items.map { |c| c.dig('sys', 'id') }.force)
            .to eq(%w[
                     6xJzDTX2HCo0u4QKIuGCOu
                     5yozzvgItUSYu4eI8yQ0ee
                   ])
        end

        it 'memoizes pages' do
          page1 = entries.merge('total' => 4)
          page2 = entries.merge('total' => 4, 'skip' => 2)
          stub_request(:get, 'https://cdn.contentful.com/spaces/1234/entries')
            .with(query: { 'limit' => 2 })
            .to_return(body: page1.to_json)
            .times(1)
          stub_request(:get, 'https://cdn.contentful.com/spaces/1234/entries')
            .with(query: { 'limit' => 2, 'skip' => 2 })
            .to_return(body: page2.to_json)
            .times(1)

          # act
          resp = client.get('entries', limit: 2)

          # assert
          resp.assert_ok!
          # first pagination
          expect(resp.items.count).to eq(4)
          # should be memoized
          expect(resp.items.map { |c| c.dig('sys', 'id') }.force)
            .to eq(%w[
                     6xJzDTX2HCo0u4QKIuGCOu
                     5yozzvgItUSYu4eI8yQ0ee
                     6xJzDTX2HCo0u4QKIuGCOu
                     5yozzvgItUSYu4eI8yQ0ee
                   ])
        end
      end

      describe 'post' do
        it 'performs a post with body' do
          stub_request(:post, 'https://cdn.contentful.com/spaces/1234/entries')
            .with(body: '{"test":"data"}')
            .to_return(status: 204)

          # act
          resp = client.post('entries', { 'test' => 'data' })

          # assert
          resp.assert_ok!
          expect(resp.status).to eq(204)
        end
      end
    end
  end
end

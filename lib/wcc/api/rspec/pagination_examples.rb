RSpec.shared_examples_for :linked_pagination_object do |url_method, base_options, total|
  it "includes link to current page" do
    url = public_send(
      url_method,
      base_options.merge(limit: 2, offset: 2)
    )
    get url
    expect(subject['_links']).to be_a(Hash)
    expect(subject['_links']['self']).to eq(url)
  end

  it "includes link to next page when there is a next page" do
    get public_send(url_method, limit: 2)
    url = public_send(url_method,
      base_options.merge(limit: 2, offset: 2)
    )
    expect(subject['_links']['next']).to eq(url)
  end

  it "does not include link to next page when this is the last page" do
    get public_send(url_method, limit: 2, offset: total - 1)
    expect(subject['_links']['next']).to be_nil
  end

  it "includes link to previous page when there is a previous page" do
    get public_send(url_method, limit: 2, offset: 2)
    url = public_send(
      url_method,
      base_options.merge(limit: 2, offset: 0)
    )
    expect(subject['_links']['previous']).to eq(url)
  end

  it "does not include link to next page when this is the last page" do
    get public_send(url_method, limit: 2)
    expect(subject['_links']['previous']).to be_nil
  end
end


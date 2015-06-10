RSpec.shared_examples_for "cached resource defaults" do
  it "sets etag" do
    expect(response.etag).to_not be_nil
  end

  it "sets public: true" do
    expect(response.cache_control[:public]).to be_truthy
  end
end

RSpec.shared_examples_for "cached member resource" do
  include_examples "cached resource defaults"

  it "sets last modified" do
    expect(response.last_modified).to_not be_nil
  end

  it "does not set max age" do
    expect(response.cache_control[:max_age]).to be_nil
  end

  it "does not set must_revalidate" do
    expect(response.cache_control[:must_revalidate]).to be_nil
  end
end

RSpec.shared_examples_for "cached collection resource" do |max_age|
  include_examples "cached resource defaults"

  it "does not set last modified" do
    expect(response.last_modified).to be_nil
  end

  it "sets must_revalidate: true" do
    expect(response.cache_control[:must_revalidate]).to be_truthy
  end

  it "sets max age" do
    expect(response.cache_control[:max_age]).to eq(max_age.to_s)
  end
end

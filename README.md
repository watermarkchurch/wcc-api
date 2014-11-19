# WCC::API

This library holds common code used in our applications that host APIs.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'wcc-api'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install wcc-api

## Usage

### `WCC::API::BaseQuery`

This provides an abstraction for building queries within an API for an
ActiveRecord backed model. You must override the `default_scope` method
to return a scope for the model you are querying on. The query object
has the following:

* `call` - calls each of the subsequent methods in order
* `paged` - adds the paging elements to the query (e.g. limit and
  offset)
* `ordered` - hook to add ordering (default does nothing)
* `filtered` - hook to add filtering (default does nothing)

The Base implementation mostly just handles the paging and provides
hooks to do other useful things. Here is an example implementation of a
query object for a generic Tag model.

```ruby
class TagQuery < WCC::API::BaseQuery
  def default_scope
    Tag.all
  end

  def ordered(scope=self.scope)
    scope.ordered
  end

  def filtered(scope=self.scope)
    Array(filter[:name_like]).each do |query|
      scope = scope.name_like(query)
    end
    scope
  end
end
```

### Pagination template

To use the common pagination object template include the view helper in
the controllers that will need it:

```ruby
class APIController < ApplicationController
  helper WCC::API::ViewHelpers
end
```

Now within your jbuilder templates you can do the following to include a
Pagination object:

```ruby
json.pagination api_pagination_for(query: @query)
```

Where `@query` conforms to the interface specified by
`WCC::API::BaseQuery`.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/wcc-api/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

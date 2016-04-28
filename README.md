# ActiveTsv

[![Build Status](https://travis-ci.org/ksss/active_tsv.svg?branch=master)](https://travis-ci.org/ksss/active_tsv)

## Usage

```tsv
id	name	age
1	ksss	30
2	foo	29
3	bar	30
```

```ruby
class User < ActiveTsv::Base
  self.table_path = "data/users.tsv"
end

User.first
#=> #<User {:id=>"1", :name=>"ksss", :age=>"30"}>
User.last
#=> #<User {:id=>"3", :name=>"bar", :age=>"30"}>
User.where(age: 30).to_a
#=> [#<User {:id=>"1", :name=>"ksss", :age=>"30"}>, #<User {:id=>"3", :name=>"bar", :age=>"30"}>]
User.where(age: 30).last
#=> #<User {:id=>"3", :name=>"bar", :age=>"30"}>
User.where(age: 30).where(name: "ksss").first
#=> #<User {:id=>"1", :name=>"ksss", :age=>"30"}>
User.where.not(name: "ksss").first
#=> #<User {:id=>"2", :name=>"foo", :age=>"29"}>
```

Also Supported **CSV**.

```ruby
require 'active_csv'
class User < ActiveCsv::Base
  self.table_path = "data/users.csv"
end
```

## Goal

Support all methods that like ActiveRecord

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_tsv'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install active_tsv

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

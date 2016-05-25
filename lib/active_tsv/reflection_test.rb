require 'active_tsv'

class User < ActiveTsv::Base
  self.table_path = "data/users.tsv"
  has_many :nicknames
  has_many :nothings
  has_one :password
  has_one :nothing

  has_many :user_books
  has_many :books, through: :user_books
end

class Nickname < ActiveTsv::Base
  self.table_path = "data/nicknames.tsv"
  belongs_to :user
  belongs_to :nothing
end

class Password < ActiveTsv::Base
  self.table_path = "data/passwords.tsv"
  belongs_to :user
end

class Book < ActiveTsv::Base
  self.table_path = "data/books.tsv"
  has_many :user_books
  has_many :users, through: :user_books
end

class UserBook < ActiveTsv::Base
  self.table_path = "data/user_books.tsv"
  belongs_to :user
  belongs_to :book
end

module ActiveTsvReflectionTest
  def test_s_has_many(t)
    [
      [User.first, %w(yuki kuri k)],
      [User.where(name: "foo").first, ["f"]],
      [User.where(name: "bar").first, []],
    ].each do |user, expect|
      r = user.nicknames
      unless ActiveTsv::Relation === r
        t.error("`#{user}.nicknames` return value broken")
      end
      unless r.all? { |i| i.instance_of?(Nickname) }
        t.error("broken reflection")
      end
      unless r.to_a.map(&:nickname) == expect
        t.error("expect #{expect} got #{r.to_a.map(&:nickname)}")
      end
    end

    begin
      User.first.nothings
    rescue NameError => e
      unless e.message == "uninitialized constant User::Nothing"
        t.error("Unexpected error message '#{e.message}'")
      end
    else
      t.error("expect raise NameError")
    end
  end

  def test_s_has_many_with_through(t)
    ksss, foo, bar = *User.all.to_a

    [
      [ksss, ["Good book", "Greate book", "Perfect book"]],
      [foo, ["Greate book"]],
      [bar, []],
    ].each do |user, expect|
      r = user.books
      unless ActiveTsv::Relation === r
        t.error("return value was broken")
      end
      unless r.map(&:title) == expect
        t.error("expect #{expect} got #{r.map(&:title)}")
      end
    end
  end

  def test_s_has_one(t)
    [
      [User.first, Password.first],
      [User.last, Password.last],
    ].each do |user, pass|
      unless Password === pass
        t.error("Unexpected instance #{pass}")
      end
      unless user.id == pass.user_id
        t.error("user.id(#{user.id}) != pass.user_id(#{pass.user_id})")
      end
      unless user.password.password == pass.password
        t.error("unexpected instance '#{user}' and '#{pass}'")
      end
    end

    begin
      User.first.nothing
    rescue NameError => e
      unless e.message == "uninitialized constant User::Nothing"
        t.error("Unexpected error message '#{e.message}'")
      end
    else
      t.error("expect raise a NameError")
    end
  end

  def test_s_belongs_to(t)
    u = Nickname.first.user
    unless User === u
      t.error("belongs_to member was break")
    end
    unless u == User.first
      t.error("expect first user")
    end

    unless Nickname.last.user.name == "foo"
      t.error("belongs_to value broken")
    end

    begin
      Nickname.first.nothing
    rescue NameError => e
      unless e.message == "uninitialized constant Nickname::Nothing"
        t.error("Unexpected error message '#{e.message}'")
      end
    else
      t.error("expect raise NameError")
    end
  end
end

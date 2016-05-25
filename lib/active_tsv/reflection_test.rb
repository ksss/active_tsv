require 'active_tsv'

class User < ActiveTsv::Base
  self.table_path = "data/users.tsv"
  has_many :nicknames
  has_many :nothings
end

class Nickname < ActiveTsv::Base
  self.table_path = "data/nicknames.tsv"
  belongs_to :user
  belongs_to :nothing
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
      unless e.message == "uninitialized constant Nothing"
        t.error("Unexpected error message #{e.message}")
      end
    else
      t.error("expect raise NameError")
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
      unless e.message == "uninitialized constant Nothing"
        t.error("Unexpected error message #{e.message}")
      end
    else
      t.error("expect raise NameError")
    end
  end
end

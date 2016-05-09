require 'active_tsv'

module ActiveTsvWhereChainTest
  class User < ActiveTsv::Base
    self.table_path = "data/users.tsv"
  end

  def test_not(t)
    r = User.where.not(age: 29)
    unless ActiveTsv::Relation === r
      t.error("break return value #{r}")
    end
    a = r.to_a
    unless a.length == 2
      t.error("expect length 2 got #{a.length}")
    end

    u = r.where.not(name: "ksss").first
    unless u && u.name == "bar" && u.age == "30"
      t.error("expect \"bar\" got #{u.inspect}")
    end
  end
end

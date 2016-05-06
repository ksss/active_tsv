require 'active_tsv'

module RelationTest
  class User < ActiveTsv::Base
    self.table_path = "data/users.tsv"
  end

  def test_where(t)
    r = User.where(age: 30).where(name: "ksss")
    unless ActiveTsv::Relation === r
      t.error("break return value #{r}")
    end
    a = r.to_a
    unless a.length == 1
      t.error("expect length 1 got #{a.length}")
    end
  end

  def test_each(t)
    r = User.where(age: 30)
    r.each do |u|
      unless User === u
        t.error("break iterate item")
      end
    end

    unless Enumerator === r.each
      t.error("break return value")
    end
  end

  def test_to_a(t)
    a = User.where(age: "30").to_a
    unless Array === a
      t.error("break return value #{a}")
    end
    unless a.length == 2
      t.error("expect length 2 got #{a.length}")
    end
  end

  def test_order(t)
    r = User.order(:age, :name)
    unless ActiveTsv::Relation === r
      t.error("break return value")
    end

    unless r.to_a.map(&:name) == ["foo", "bar", "ksss"]
      t.error("miss order")
    end

    unless User.order(:name).where.not(age: 29).map(&:name) == User.where.not(age: 29).order(:name).map(&:name)
      t.error("expect match order where.order and order.where")
      t.log(User.order(:name).where.not(age: 29).map(&:name), User.where.not(age: 29).order(:name).map(&:name))
    end
  end
end

require 'active_tsv'

module ActiveTsvRelationTest
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

  def test_equal(t)
    unless User.all == User.all
      t.error("expect same")
    end
    unless User.where.not(age: 30).where(name: 'ksss') == User.where.not(age: 30).where(name: 'ksss')
      t.error("expect same")
    end
  end

  def test_where_scope(t)
    r = User.all
    r1 = r.where(age: 30)
    r2 = r.where(name: 'ksss')
    unless r1.to_a.length == 2
      t.error("expect keep scope but dose not")
    end

    unless r2.to_a.length == 1
      t.error("expect keep scope but dose not")
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

  def test_order_reorderable(t)
    r = User.order(:name).where.not(age: 29)
    first_last = nil
    r.each { |i| first_last = i }
    second_last = nil
    r.each { |i| second_last = i }
    unless first_last.name == second_last.name
      t.error("break order_values")
    end
  end

  def test_take(t)
    r = User.all
    unless r.take(2).length == 2
      t.error("take(2) expect get length 2")
    end

    unless r.take.name == "ksss"
      t.error("take expect like first")
    end
  end

  def test_group(t)
    r = User.all
    unless r.count == 3
      t.error("expect count 3 got #{r.count}")
    end

    one = r.group(:age).count
    expect = { "30" => 2, "29" => 1 }
    unless one == expect
      t.error("expect #{expect} got #{one}")
    end

    two = r.group(:age, :name).count
    expect = { ["30", "ksss"] => 1, ["29", "foo"] => 1, ["30", "bar"] => 1 }
    unless two == expect
      t.error("expect #{expect} got #{two}")
    end
  end
end

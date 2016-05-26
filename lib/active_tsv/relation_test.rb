require 'active_tsv'

module ActiveTsvRelationTest
  class User < ActiveTsv::Base
    self.table_path = "data/users.tsv"
  end

  def test_find(t)
    unless User.find(1).name == "ksss"
      t.error("Couldn't find 'id'=1")
    end

    unless User.where(age: 30).find(1).name == "ksss"
      t.error("Couldn't find 'id'=1")
    end

    unless User.find(1, 2).map(&:name) == ["ksss", "foo"]
      t.error("Couldn't find 'id'=1 and 2")
    end

    c = Struct.new(:code, :expect)
    [
      c.new(-> { User.find }, "Couldn't find ActiveTsvRelationTest::User without an ID"),
      c.new(-> { User.where(age: 300).find(1) }, "Couldn't find ActiveTsvRelationTest::User with 'id'=1"),
      c.new(-> { User.find(100) }, "Couldn't find ActiveTsvRelationTest::User with 'id'=100"),
      c.new(-> { User.find(1, 100) }, "Couldn't find all ActiveTsvRelationTest::User with 'id': (1, 100) (found 1 results, but was looking for 2)"),
    ].each do |set|
      begin
        set.code.call
      rescue ActiveTsv::RecordNotFound => e
        unless e.message == set.expect
          t.error("Unexpected error message")
        end
      else
        t.error("expect ActiveTsv::RecordNotFound")
      end
    end
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

  def test_where_in(t)
    cond = ["1", "2"]
    unless User.where(id: cond).map(&:name) == ["ksss", "foo"]
      t.error("break where id in #{cond}")
    end

    unless User.where.not(id: cond).map(&:name) == ["bar"]
      t.error("break where id not in #{cond}")
    end

    unless User.where(id: 1..2).map(&:name) == ["ksss", "foo"]
      t.error("break where id in #{cond}")
    end
  end

  def test_where_not_support(t)
    r = User.all
    r.where_values << Struct.new(:foo).new('foo')
    begin
      r.to_a
    rescue ActiveTsv::Condition::NotSupportError
    else
      t.error("expect raise an error ActiveTsv::Condition::NotSupportError, but nothing")
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

  def test_pluck(t)
    unless User.pluck == User.all.to_a.map { |i| [i.id, i.name, i.age] }
      t.error("break values")
    end

    unless User.pluck(:id) == User.all.to_a.map(&:id)
      t.error("break values")
    end

    unless User.order(:name).pluck(:id) == User.order(:name).to_a.map(&:id)
      t.error("break values")
    end

    unless User.pluck(:id, :name) == User.all.to_a.map { |i| [i.id, i.name] }
      t.error("break values")
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

  def test_order_desc(t)
    unless User.order(name: :desc).map(&:name) == User.order(:name).map(&:name).reverse
      t.error("order descending is not equal reverse it")
    end

    unless User.order(age: :asc).order(name: :desc).map(&:name) == ["foo", "ksss", "bar"]
      t.error("ordering was break")
    end

    begin
      User.order(age: :typo)
    rescue ArgumentError
    else
      t.error("expect raise ArgumentError")
    end
  end

  def test_ordered_first_and_last(t)
    unless User.order(:name).first.name == "bar"
      t.error("first record didn't change by order")
    end
    unless User.order(:name).last.name == "ksss"
      t.error("last record didn't change by order")
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

  def test_take_with_order(t)
    unless User.order(:name).take(2).map(&:name) == ["bar", "foo"]
      t.error("`take` should consider order")
    end

    unless User.order(:name).take.name == "bar"
      t.error("`take` should consider order")
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

  def test_maximum(t)
    unless User.maximum(:name) == "ksss"
      t.error("Cannot get maximum value")
    end

    unless User.where.not(name: "ksss").maximum(:name) == "foo"
      t.error("Cannot get maximum value")
    end

    unless User.where.not(id: "1").where.not(id: "2").where.not(id: "3").maximum(:id).nil?
      t.error("expect nil")
    end
  end

  def test_minimum(t)
    unless User.minimum(:name) == "bar"
      t.error("Cannot get maximum value")
    end

    unless User.where.not(name: "bar").minimum(:name) == "foo"
      t.error("Cannot get maximum value")
    end

    unless User.where.not(id: "1").where.not(id: "2").where.not(id: "3").minimum(:id).nil?
      t.error("expect nil")
    end
  end
end

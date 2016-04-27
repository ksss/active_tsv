require 'active_tsv'

module ActiveTsvTest
  class User < ActiveTsv::Base
    self.table_path = "data/users.tsv"
  end

  def test_initialize(t)
    u = User.new
    unless User === u
      t.error("break return value")
    end

    {
      id:   nil,
      name: nil,
      age:  nil,
    }.each do |k, v|
      unless u[k] == v
        t.error("User##{k} expect #{v} got #{u[k]}")
      end
    end

    [
      -> { User.new(1) },
      -> { User.new([1]) },
    ].each do |block|
      begin
        block.call
      rescue ArgumentError
      else
        t.error("Should raise ArgumentError but nothing")
      end
    end
  end

  def test_where(t)
    r = User.where(age: "30")
    unless ActiveTsv::Relation === r
      t.error("return value was break")
    end
  end

  def test_first(t)
    u = User.first
    unless User === u
      t.error("return value was break")
    end

    {
      id:   "1",
      name: "ksss",
      age:  "30",
    }.each do |k, v|
      unless u[k] == v
        t.error("User##{k} expect #{v} got #{u[k]}")
      end
    end
  end

  def test_last(t)
    u = User.last
    unless User === u
      t.error("break return value")
    end

    {
      id:   "3",
      name: "bar",
      age:  "30",
    }.each do |k, v|
      unless u[k] == v
        t.error("User##{k} expect #{v} got #{u[k]}")
      end
    end
  end
end

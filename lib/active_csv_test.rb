require 'active_csv'

module ActiveCsvTest
  class User < ActiveCsv::Base
    self.table_path = "data/users.csv"
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
end

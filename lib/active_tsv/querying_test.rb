require 'active_tsv'

module ActiveTsvQueryingTest
  class User < ActiveTsv::Base
    self.table_path = "data/users.tsv"
  end

  def test_delegate(t)
    r = User.all
    ActiveTsv::Querying::METHODS.each do |m|
      unless r.respond_to?(m)
        t.error("expect delegate to Relation `#{m}' but nothing")
      end
    end
  end
end

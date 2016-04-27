# frozen_string_literal: true

require 'active_tsv'

module ActiveCsv
  class Base < ActiveTsv::Base
    SEPARATER = ","
  end
end

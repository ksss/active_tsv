module ActiveTsv
  ActiveTsvError = Class.new(StandardError)
  RecordNotFound = Class.new(ActiveTsvError)
end

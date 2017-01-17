module ActiveTsv
  ActiveTsvError = Class.new(StandardError)
  RecordNotFound = Class.new(ActiveTsvError)
  StatementInvalid = Class.new(ActiveTsvError)
  UnknownAttributeError = Class.new(NoMethodError)
end

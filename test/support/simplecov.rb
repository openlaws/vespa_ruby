require "simplecov"

SimpleCov.start do
  add_filter "test/"
  enable_coverage :branch
  primary_coverage :branch
end

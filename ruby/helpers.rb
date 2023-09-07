# frozen_string_literal: true

def valid_number?(string, limit)
  x = Integer(string)
  x >= 0 && x < limit
rescue ArgumentError
  false
end

def input_line
  $stdin.gets.chomp
end

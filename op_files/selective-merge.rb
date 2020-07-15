#!/usr/bin/env ruby

require 'yaml'

template_path = ARGV[0]
input_path = ARGV[1]

class Operation
  def self.is_operation?(string)
    !(string =~ /\(\(.*\)\)/).nil?
  end

  def self.handle(string, input)
    op, path = self.parse_operation(string)

    case op
    when "grab"
      input.dig(*path.split("."))
    end
  end

  private

  def self.parse_operation(string)
    result = string.match(/\(\(\s*(\w+)\s(.*)\)\)/)
    [result[1], result[2].strip]
  end
end

class Template
  def initialize(path, input_path)
    @yaml = YAML.load_file(path)
    @input = YAML.load_file(input_path)
  end

  def evaluate
    new = {}
    @yaml.each do |key, value|
      new[key] = evaluate_value(value)
    end
    new
  end

  def to_s
    puts "Template: "
    YAML.dump @yaml
    puts "Input data: "
    YAML.dump @input
  end

  private

  def evaluate_value(object)
    case object
    when String
      if Operation.is_operation?(object)
        Operation.handle(object, @input)
      else
        object
      end

    when Array
      object.map { |element| evaluate_value(element) }
    when Hash
      Hash[object.map { |key, value|
        [key, evaluate_value(value)]
      }]
    else
      object
    end
  end
end

t = Template.new(template_path, input_path)
puts YAML.dump(t.evaluate)

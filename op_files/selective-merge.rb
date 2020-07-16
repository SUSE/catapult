#!/usr/bin/env ruby

# example usage:
# ./selective_merge.rb -d kubecf=kubecf-values.yaml -p stratos-loadbalancer-patch.yaml

require 'yaml'
require 'json'
require 'open3'

require 'slop'

opts = Slop.parse do |o|
  o.string "-p", "--patch", "path to the patch file"
  o.array "-d", "--dependency", "path to a yaml file of a dependency"
end

template_path = opts[:patch]
dependency_definitions = opts[:dependency]

class Spec
  def initialize(yaml, dependencies)
    @yaml = yaml
    @dependencies = dependencies
  end

  def target
    @yaml["apply_to"]
  end

  def target_yaml
    @dependencies[@yaml["apply_to"]] if @yaml.has_key?("apply_to")
  end

  def match_conditions?
    deps = @yaml["depends_on"]

    return true if !deps

    deps.all? do |dep|
      conditions = dep["conditions"] || []
      conditions.all? do |condition|
        output, status = Open3.capture2e("jq", "-e", condition, stdin_data: @dependencies[dep["name"]].to_json)

        if !status.success?
          STDERR.puts "Running jq failed on the condition '#{condition}':\n\n#{output}"
          exit 1
        else
          true
        end
      end
    end
  end
end

class Operation
  def self.is_operation?(string)
    !(string =~ /\(\(.*\)\)/).nil?
  end

  def initialize(op, dependencies)
    @op = op
    @dependencies = dependencies
  end

  def handle
    op, target, path = parse_operation(@op)

    case op
    when "grab"
      @dependencies[target].dig(*path.split("."))
    end
  end

  private

  def parse_operation(string)
    result = string.match(/\(\(\s*(\w+)\s(.*)\#(.*)\)\)/)
    [result[1], result[2].strip, result[3].strip]
  end
end

class Template
  def initialize(template)
    @yaml = template
  end

  def evaluate(dependencies)
    new = {}
    @yaml.each do |key, value|
      new[key] = evaluate_value(value, dependencies)
    end
    new
  end

  def apply(target, dependencies)
    merge_data = evaluate(dependencies)
    deep_merge(target, merge_data)
  end

  private

  def deep_merge(first_hash, other_hash)
    first_hash.merge(other_hash) do |key, oldval, newval|
      oldval = oldval.to_hash if oldval.respond_to?(:to_hash)
      newval = newval.to_hash if newval.respond_to?(:to_hash)
      oldval.class.to_s == 'Hash' && newval.class.to_s == 'Hash' ? deep_merge(oldval, newval) : newval
    end
  end

  def evaluate_value(object, dependencies)
    case object
    when String
      if Operation.is_operation?(object)
        Operation.new(object, dependencies).handle
      else
        object
      end

    when Array
      object.map { |element| evaluate_value(element, dependencies) }
    when Hash
      Hash[object.map { |key, value|
        [key, evaluate_value(value, dependencies)]
      }]
    else
      object
    end
  end
end




dependencies = {}
dependency_definitions.each do |definition|
  name, path = definition.split("=")
  dependencies[name] = YAML.load_file(path)
end

spec_yaml, template_yaml = YAML.load_stream(File.read(template_path))
spec = Spec.new(spec_yaml, dependencies)

if spec.match_conditions?
  template = Template.new(template_yaml)

  if spec.target.nil?
    puts YAML.dump(template.evaluate(dependencies))
  else
    result = template.apply(spec.target_yaml, dependencies)
    # Prevent YAML.dump from adding anchors by loading a json representation of it
    puts YAML.dump(YAML.load(result.to_json))
  end
else
  STDERR.puts "Conditions were not met."
  exit 1
end

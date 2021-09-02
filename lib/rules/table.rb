require 'method_source'
require_relative 'sequence'

module Rules
  class Table < BasicObject
    attr_reader :__fields

    def initialize
      @__fields = {}
    end

    def [](field)
      __fields[field]
    end

    def has_field?(field)
      __fields.has_key? field
    end

    def method_missing(name, *args, &block)
      if name == :sequence
        __fields[args[0]] = ::Rules::Sequence.new(&block)
      else
        __fields[name] = if block
          block
        else
          args[0]
        end
      end
    end

    def is_a?(klass)
      klass == ::Rules::Table
    end

    def to_s
      __fields.map do |name, value|
        if value.is_a? ::Proc
          "#{value.source.strip}"
        else
          "#{name} #{value.inspect}"
        end
      end.join("\n")
    end

    def inspect
      "#<Rules::Table #{__fields.inspect}>"
    end
  end
end

require_relative 'rules/definition_proxy'

module Rules
  @tables = Hash.new { |hash, name| hash[name] = Table.new }

  def self.tables
    @tables
  end

  def self.table(name)
    tables[name]
  end

  def self.define(&block)
    definition_proxy = DefinitionProxy.new
    definition_proxy.instance_eval(&block)
  end

  def self.to_s
    tables.map do |name, table|
      "#{name} table:\n#{table.to_s.gsub(/^/, '  ')}"
    end.join("\n")
  end
end

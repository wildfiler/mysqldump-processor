require_relative 'table'

module Rules
  class DefinitionProxy
    def table(name, &block)
      table = Rules.table name
      table.instance_eval(&block)
    end

    def tables(*names, &block)
      names.each do |name|
        table = Rules.table name
        table.instance_eval(&block)
      end
    end
  end
end

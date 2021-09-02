class TableDefinition
  attr_reader :name, :fields

  def initialize(name, fields)
    @name = name
    @fields = fields
  end

  def [](field)
    field_index(field)
  end

  private

  def field_index(field)
    fields_indexes[field.to_s]
  end

  def fields_indexes
    @fields_indexes ||= fields.each.with_index.to_h
  end
end

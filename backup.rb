require 'sql-parser'
require 'bcrypt'

module SQLParser
  class SQLVisitor
    def visit_InValuesList(o)
      compact_arrayize(o.values)
    end

    def visit_InValueList(o)
      "(#{compact_arrayize(o.values)})"
    end

    private

    def compact_arrayize(arr)
      visit_all(arr).join(',')
    end
  end
end

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


parser = SQLParser::Parser.new
dump_filename = ARGV[0]

dump = File.open(dump_filename)

basename = File.basename(dump_filename, '.*')
ext = File.extname(dump_filename)

out_file = File.open("#{basename}.anonym#{ext}", "w")

state = :find_create
table_name = nil
fields = []
table_definitions = {}

rules = {
  clients: {
    encrypted_password: -> (_) { ::BCrypt::Password.create('123456') },
    confirmation_token: nil,
    reset_password_token: nil,
  }
}

dump.each do |line|
  out_buf = line
  case state
  when :find_create
    m = line.match(/CREATE TABLE `(?<table_name>\w*)`/)
    if m
      table_name = m[:table_name]
      state = :find_fields
    end
  when :find_fields
    m = line.match(/^\s*`(?<id>\w*)`,?/)

    if m
      fields << m[:id]
    end

    if line.end_with?(";\n")
      state = :find_insert
      table_definitions[table_name] = TableDefinition.new(table_name, fields)
      # puts "#{table_name}: #{fields.length}."
      fields = []
      table_name = nil
    end
  when :find_insert
    m = line.match(/^INSERT INTO `(?<table_name>\w*)` VALUES/)
    if m
      table = m[:table_name].to_sym
      if rules.keys.include? table
        table_rules = rules[table]
        ast = parser.scan_str(line.delete_suffix(";\n"))

        ast.in_values_list.values.each do |in_value_list|
          in_value_list.values = in_value_list.values.map.with_index do |in_value, index|
            field = table_definitions[table.to_s].fields[index].to_sym
            next in_value unless table_rules.has_key?(field)


            rule = rules[table][field]
            case rule
            when Proc
              in_value.class.new(rule.(in_value.value))
            when nil
              SQLParser::Statement::Null.new
            else
              in_value
            end
          end
        end

        out_buf = ast.to_sql + ";\n"
      end

      state = :find_create
    end
    if line.start_with?('DROP TABLE IF EXISTS')
      state = :find_create
    end
  end

  out_file.write(out_buf)
end

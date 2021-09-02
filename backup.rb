require 'sql-parser'
require_relative 'lib/sql_parser/sql_visitor'
require_relative 'lib/table_definition'
require_relative 'lib/rules'

load ARGV[0]
puts Rules.to_s
puts

parser = SQLParser::Parser.new
dump_filename = ARGV[1]

dump = File.open(dump_filename)

basename = File.basename(dump_filename, '.*')
ext = File.extname(dump_filename)

out_file = File.open("#{basename}.anonym#{ext}", "w")

state = :find_create
table_name = nil
fields = []
table_definitions = {}

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
      fields = []
      table_name = nil
    end
  when :find_insert
    m = line.match(/^INSERT INTO `(?<table_name>\w*)` VALUES/)
    if m
      table = m[:table_name].to_sym
      if Rules.tables.has_key? table
        table_rules = Rules.tables[table]
        start_at = Time.new
        ast = begin
          parser.scan_str(line.delete_suffix(";\n"))
        rescue Racc::ParseError => e
          puts "Error on `#{table}`"
          puts parser.inspect
          raise
        end
        puts "Parsed `#{table}` in #{Time.now - start_at}s"

        start_at = Time.new
        ast.in_values_list.values.each do |in_value_list|
          in_value_list.values = in_value_list.values.map.with_index do |in_value, index|
            field = table_definitions[table.to_s].fields[index].to_sym
            # puts "#{field} => #{table_rules.has_field?(field)}"
            next in_value unless table_rules.has_field?(field)

            rule = table_rules[field]
            case rule
            when Proc
              case in_value
              when SQLParser::Statement::Null
                new_value = rule.(nil)
                case new_value
                when String
                  SQLParser::Statement::String.new(new_value)
                when Integer
                  SQLParser::Statement::Integer.new(new_value)
                when Float
                  SQLParser::Statement::Integer.new(new_value)
                when true
                  SQLParser::Statement::True.new
                when false
                  SQLParser::Statement::False.new
                when nil
                  SQLParser::Statement::Null.new
                else
                  raise 'Unknown column type'
                end
              else
                in_value.class.new(rule.(in_value.value))
              end
            when nil
              SQLParser::Statement::Null.new
            else
              in_value.class.new(rule)
            end
          end
        end

        puts "Processed `#{table}` in #{Time.now - start_at}s"
        puts
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

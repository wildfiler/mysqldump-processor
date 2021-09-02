require 'sql-parser'

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

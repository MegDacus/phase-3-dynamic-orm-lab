require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord

    def self.table_name
        self.to_s.downcase.pluralize
    end

    def self.column_names
        DB[:conn].results_as_hash = true

        table_info = DB[:conn].execute("PRAGMA table_info('#{table_name}')")
        column_names = []
        table_info.each do |column|
            column_names << column['name']
        end

        column_names.compact
    end

    def initialize(options = {})
        options.each do |key, value|
            self.send("#{key}=", value)
        end
    end

    def table_name_for_insert
        self.class.table_name
    end

    def col_names_for_insert
        self.class.column_names.delete_if {|col| col == "id"}.join(", ")
    end

    def values_for_insert
        values = []
        self.class.column_names.each do |col|
            values << "'#{send(col)}'" unless send(col).nil?
        end
        values.join(", ")
    end

    def save
        DB[:conn].execute("INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})")

        @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0] 
    end

    def self.find_by_name(name)
        DB[:conn].execute("SELECT * FROM #{table_name} WHERE name == ?", name)
    end

    def self.find_by(attr_hash)
        value = attr_hash.values.first
        DB[:conn].execute("SELECT * FROM #{table_name} WHERE #{attr_hash.keys.first} == '#{attr_hash.values.first}'")
    end

end
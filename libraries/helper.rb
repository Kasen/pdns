module Pdns
  # Helper functions
  module Helper
    # Returns true if database schema exist
    #
    # @param [Hash] connection_info
    # @param [String] database
    #
    # @return [TrueClass, FalseClass]
    def schema_exists?(connection_info, database)
      require 'mysql2'
      db = mysql_connection(connection_info, database)
      db.query('show tables').any?
    end

    def mysql_connection(mysql_connection_info, database = nil)
      require 'mysql2'
      Mysql2::Client.new(host: mysql_connection_info[:host],
                         port: mysql_connection_info[:port] || 3306,
                         username: mysql_connection_info[:username],
                         password: mysql_connection_info[:password],
                         database: database,
                         socket: mysql_connection_info[:socket] || nil)
    end
  end
end

Chef::Recipe.send(:include, Pdns::Helper)
Chef::Resource.send(:include, Pdns::Helper)

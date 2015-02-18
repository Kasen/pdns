class Chef
  class Provider
    class Database
      class Mysql
        def action_query
          begin
            query_sql = new_resource.sql_query
            Chef::Log.debug("Performing query [#{query_sql}]")
            query_client.query(query_sql)
          ensure
            close_query_client
          end
        end

        private

        def query_client
          require 'mysql2'
          @query_client ||=
            Mysql2::Client.new(
            host: new_resource.connection[:host],
            socket: new_resource.connection[:socket],
            username: new_resource.connection[:username],
            password: new_resource.connection[:password],
            port: new_resource.connection[:port],
            database: new_resource.database_name || nil
            )
        end
      end
    end
  end
end

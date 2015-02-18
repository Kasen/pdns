include_recipe 'pdns::server'

mysql_item = encrypted_data_bag_item(node['pdns']['data_bag'], node['pdns']['data_bag_item'])

mysql_connection_info = {
  :host     => 'localhost',
  :username => 'root',
  :password => mysql_item['server_root_password']
}

cookbook_file ::File.join(Chef::Config['file_cache_path'], 'database.sql') do
  source "database.sql"
  owner "root"
  group "root"
  mode "0644"
end

mysql_database mysql_item['db_name'] do
  connection mysql_connection_info
  sql "TRUNCATE TABLE records;"
  action :query
end

mysql_database mysql_item['db_name'] do
  connection mysql_connection_info
  sql "TRUNCATE TABLE domains;"
  action :query
end

execute "Test_data_uploading" do
  command "mysql -u root -p#{mysql_item['server_root_password']} #{mysql_item['db_name']} < #{::File.join(Chef::Config['file_cache_path'], 'database.sql')}"
  user 'root'
  group 'root'
  timeout 3600
  returns 0
end

file '/etc/resolv.conf' do
  action :create
  owner 'root'
  group 'root'
  mode '0644'
  content "nameserver 127.0.0.1\nnameserver 8.8.8.8"
end

package "bind-utils" do
  action :install
  only_if { platform_family?("rhel") }
end

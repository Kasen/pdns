include_recipe 'chef-sugar'

mysql_item = encrypted_data_bag_item(node['pdns']['data_bag'], node['pdns']['data_bag_item'])

mysql_service 'default' do
  version '5.6'
  server_root_password mysql_item['server_root_password']
  allow_remote_root false
  action :create
end

mysql2_chef_gem 'default' do
  action :install
end

mysql_connection_info = {
  :host => 'localhost',
  :username => 'root',
  :password => mysql_item['server_root_password']
}

# Create database
mysql_database mysql_item['db_name'] do
  connection mysql_connection_info
  encoding 'utf8'
  collation 'utf8_general_ci'
  action :create
end

# Create user
mysql_database_user mysql_item['db_user'] do
  connection mysql_connection_info
  password mysql_item['db_password']
  database_name mysql_item['db_name']
  host 'localhost'
  privileges [:all]
  action :grant
end

cookbook_file ::File.join(Chef::Config[:file_cache_path], 'mysql_pdns_schema.sql') do
  source 'mysql_schema.sql'
  owner 'root'
  group 'root'
  mode '0644'
end

# action :query broken now in database cookbook
execute "Schema_creating" do
  command "mysql -u root -p#{mysql_item['server_root_password']} #{mysql_item['db_name']} < #{::File.join(Chef::Config[:file_cache_path], 'mysql_pdns_schema.sql')}"
  user 'root'
  group 'root'
  timeout 3600
  returns 0
  not_if { schema_exists?(mysql_connection_info, mysql_item['db_name']) }
end

package 'pdns-backend-mysql' do
  action :install
end

template ::File.join(node['pdns']['server']['config_dir'], 'conf.d', 'backend.conf') do
  source 'mysql-backend.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(:dbname => mysql_item['db_name'],
            :password => mysql_item['db_password'],
            :user => mysql_item['db_user'])
  notifies :restart, 'service[pdns]'
end

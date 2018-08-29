node[:deploy].each do |app_name, deploy|
  package 'sendmail' do
    action :install
  end

  service 'sendmail' do
    action [ :enable, :start ]
  end

  package 'php5-cli' do 
    action :install
  end

  directory "/opt/dbkup" do
    owner "root"
    group "root"
    mode 00777
    action :create
  end

  template "/opt/dbkup/db-connect.php" do
    source "db-connect.php.erb"
    mode 0660
    group deploy[:group]

    if platform?("ubuntu")
      owner "www-data"
    elsif platform?("amazon")
      owner "apache"
    end

    variables(
      :host =>     (deploy[:database][:host] rescue nil),
      :user =>     (deploy[:database][:username] rescue nil),
      :password => (deploy[:database][:password] rescue nil),
      :db =>       (deploy[:database][:database] rescue nil),
      :table =>    (node[:phpapp][:dbtable] rescue nil)
    )
  end

  template "/opt/dbkup/db-backup.php" do
    source "db-backup.php.erb"
    mode 0755
    group deploy[:group]
    owner "root"
  end

  cron "noop" do
    hour "0"
    minute "0"
    command "cd /opt/dbkup && php /opt/dbkup/db-backup.php"
  end
end

cert_path = node["ssl_settings"]["cert_path"]
ca_path = node["ssl_settings"]["ca_path"]

["/etc/pki/tls/certs", "/usr/local", "/usr/local/etc", cert_path, ca_path, "#{ca_path}/keys", "#{ca_path}/requests", "#{ca_path}/certs", "#{ca_path}/newcerts"].each do |dir|
  directory dir do
    recursive true
  end
end

file "#{ca_path}/index.txt.attr" do
  content "unique_subject = no\n"
end

file "#{ca_path}/index.txt"

execute "create serial" do
  command "echo '01\n' > #{ca_path}/serial"
  not_if { ::File.exists?("#{ca_path}/serial") }
end

execute "generate key" do
  command "openssl genrsa -des3 -passout pass:password -out #{ca_path}/keys/ca.key 1024"
  not_if { ::File.exists?("#{ca_path}/keys/ca.key") }
end

execute "generate ca" do
  command "cd #{ca_path} && openssl req -new -x509 -days 1001 -key #{ca_path}/keys/ca.key -passin pass:password -out #{ca_path}/certs/ca.cert -subj '/CN=mydomain.com/OU=Org Unit/O=My Org Pty Ltd/L=Sydney/ST=NSW/C=AU/emailAddr=someone@example.com'"
  not_if { ::File.exists?("#{ca_path}/certs/ca.cert")}
end

execute "generate server key" do
  command "openssl genrsa 1024 > #{cert_path}/server.key"
  not_if { ::File.exists?("#{cert_path}/server.key")}
end

execute "generate request" do
  command "openssl req -new -key #{cert_path}/server.key -out #{cert_path}/request.csr -subj '/CN=#{node["ssl_settings"]["common_name"]}/OU=Org Unit/O=My Org Pty Ltd/L=Sydney/ST=NSW/C=AU/emailAddr=someoneATexample.com'"
  not_if { ::File.exists?("#{cert_path}/request.csr")}
end

execute "sign request with CA" do
  command "cd #{ca_path}/.. && openssl ca -policy policy_anything -cert #{ca_path}/certs/ca.cert -batch -in #{cert_path}/request.csr -passin pass:password  -keyfile #{ca_path}/keys/ca.key -days 9999 -out #{cert_path}/signed.cert"
  not_if { ::File.exists?("#{cert_path}/signed.cert")}
end
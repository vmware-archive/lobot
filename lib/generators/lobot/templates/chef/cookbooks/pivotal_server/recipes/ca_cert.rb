cookbook_file "/etc/pki/tls/certs/ca-bundle.crt" do
  source "cacert.pem"
  mode "0444"
end

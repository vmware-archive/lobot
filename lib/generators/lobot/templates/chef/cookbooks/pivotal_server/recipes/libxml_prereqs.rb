{
  "libxslt" => "1.1.17-2.el5_2.2",
  "libxslt-devel" => "1.1.17-2.el5_2.2",
}.each do |package_name, version_string|
  ['x86_64'].each do |arch_string|
    yum_package package_name do
      action :install
      version version_string
      # arch arch_string
    end
  end
end

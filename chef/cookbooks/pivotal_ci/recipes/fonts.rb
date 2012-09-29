%w(xfonts-base xfonts-75dpi xfonts-100dpi xfonts-scalable xfonts-cyrillic).each do |font|
  package font do
    action :install
  end
end

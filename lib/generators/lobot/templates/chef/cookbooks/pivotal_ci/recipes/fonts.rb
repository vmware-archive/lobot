%w(xorg-x11-fonts-Type1 xorg-x11-fonts-75dpi bitmap-fonts xorg-x11-fonts-ISO8859-1-75dpi xorg-x11-fonts-truetype xorg-x11-fonts-ISO8859-15-75dpi xorg-x11-fonts-ISO8859-15-100dpi xorg-x11-fonts-ISO8859-1-100dpi liberation-fonts dejavu-lgc-fonts).each do |font|
  yum_package font do
    action :install
  end
end

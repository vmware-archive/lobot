

src_dir = "/usr/local/src/imagemagick"

directory src_dir

run_unless_marker_file_exists("imagemagick_6_6_5") do
  execute "install imagemagic prerequisites" do
    command "yum -y install tcl-devel libpng-devel libjpeg-devel ghostscript-devel bzip2-devel freetype-devel libtiff-devel"
  end

  execute "download imagemagick" do
    command "curl -Lsf ftp://ftp.imagemagick.org/pub/ImageMagick/ImageMagick-6.6.5-10.tar.gz| tar xvz -C#{src_dir} --strip 1"
  end

  execute "configure imagemagick" do
    command "./configure --prefix=/usr/local --with-bzlib=yes --with-fontconfig=yes --with-freetype=yes --with-gslib=yes --with-gvc=yes --with-jpeg=yes --with-jp2=yes --with-png=yes --with-tiff=yes"
    cwd src_dir
  end

  execute "make clean" do
    command "make clean"
    cwd src_dir
  end

  execute "make imagemagic" do
    command "make"
    cwd src_dir
  end

  execute "make install" do
    command "make install"
    cwd src_dir
  end
end

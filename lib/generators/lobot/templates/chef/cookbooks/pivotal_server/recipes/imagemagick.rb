

src_dir = "/usr/local/src/imagemagick"

directory src_dir

run_unless_marker_file_exists("imagemagick_6_6_5") do
  execute "install imagemagic prerequisites" do
    command "yum -y install tcl-devel libpng-devel libjpeg-devel ghostscript-devel bzip2-devel freetype-devel libtiff-devel"
  end

  execute "download imagemagick" do
    # using an older version because the URL for the current version dies when a new version comes out.
    # http://www.ics.uci.edu/~fielding/pubs/dissertation/rest_arch_style.htm
    command "curl -Lsf ftp://ftp.imagemagick.org/pub/ImageMagick/legacy/ImageMagick-6.6.5-10.tar.gz | tar xvz -C#{src_dir} --strip 1"
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

file "/etc/ld.so.conf.d/imagemagick.conf" do
  content "/usr/local/lib"
end

execute "add imagemagick to ldconf" do
  command "/sbin/ldconfig"
end

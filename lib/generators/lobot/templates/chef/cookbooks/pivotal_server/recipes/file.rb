src_dir = "/usr/local/src/file"

run_unless_marker_file_exists("file") do
  execute "download file src" do
    command "mkdir -p #{src_dir} && curl -Lsf ftp://ftp.astron.com/pub/file/file-5.08.tar.gz | tar xvz -C#{src_dir} --strip 1"
  end

  execute "configure file" do
    command "cd #{src_dir} && ./configure"
  end

  execute "make file" do
    command "cd #{src_dir} && make"
  end

  execute "install file" do
    command "cd #{src_dir} && make install"
  end
end

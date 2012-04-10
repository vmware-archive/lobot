swapfile_location = "/swapfile"
swap_in_megabytes = 512

execute "create swapfile" do
  command "dd if=/dev/zero of=#{swapfile_location} bs=1024 count=#{swap_in_megabytes*1024}"
  not_if { File.exists?(swapfile_location) }
end

execute "mkswap" do
  command "mkswap /swapfile"
  not_if "file #{swapfile_location} | grep -q 'swap file'"
end

execute "swapon" do
  command "swapon #{swapfile_location}"
  not_if "cat /proc/swaps  | grep -q '/swapfile'"
end

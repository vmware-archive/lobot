# Travis Essentials
#
include_recipe "build-essential"
include_recipe "networking_basic"
include_recipe "sysctl"
include_recipe "unarchivers"

# additional libraries needed to run headless WebKit,
# build parsers, for ossp-uuid to work and so on
#
include_recipe "libqt4"
include_recipe "libgdbm"
include_recipe "libncurses"
include_recipe "libossp-uuid"
include_recipe "libffi"
include_recipe "ragel"
include_recipe "imagemagick"

# Node.js for asset pipeline support
#
include_recipe "nodejs::multi"

# Data stores
#
include_recipe "postgresql::client"
include_recipe "mysql::client"
include_recipe "mysql::server_on_ramfs"
include_recipe "postgresql::server_on_ramfs"

# Headless WebKit, browsers, Selenium toolchain, etc
#
include_recipe "xserver"
include_recipe "firefox"
include_recipe "chromium"
include_recipe "phantomjs::tarball"

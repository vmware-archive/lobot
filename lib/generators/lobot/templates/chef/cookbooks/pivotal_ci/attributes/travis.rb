travis_yaml = <<eos
json:
  rvm:
    default: 1.8.7
    rubies:
    - name: 1.9.3
    - name: rbx-head
      arguments: --branch 2.0.testing
      using: 1.8.7
    - name: rbx-head
      arguments: -n d19 --branch 2.0.testing -- --default-version=1.9
      using: 1.9.3
      check_for: rbx-head-d19
    - name: 1.8.7
    - name: jruby
    - name: ree
    - name: 1.9.2
    - name: ruby-head
    - name: 1.8.6
    gems:
      - bundler
      - rake
      - chef
    aliases:
      rbx: rbx-head
      rbx-2.0: rbx-head
      rbx-2.0.0pre: rbx-head
      rbx-18mode: rbx-head
      rbx-19mode: rbx-head-d19
  mysql:
    server_root_password: ""
  postgresql:
    max_connections: 256
  travis_build_environment:
    use_tmpfs_for_builds: false
eos

travis_config = YAML.load(travis_yaml)
default.merge(travis_config['json'])
default["nginx_settings"] ||= {}
default["nginx_settings"]["basic_auth_users"] = CI_CONFIG['basic_auth']

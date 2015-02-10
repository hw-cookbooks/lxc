include_recipe 'apt::default'
include_recipe 'lxc::default'

# Mocking a chef server inside the lxc host so 
# chef-client inside the container can "register" into the server

execute 'run chef-zero' do
  command '/opt/chef/bin/chef-zero --host 10.0.3.1 --port 8889 --daemon'
  action :run
end

container_name = 'test-container'

lxc_container container_name do
  action :create
  chef_enabled true
  chef_log_location '/var/log/chef/chef-client.log'
  chef_client_version '11.18.6'
  run_list [ ]
  node_name container_name
  validation_client 'chef-validator'
  server_uri node['chef_client']['config']['chef_server_url']
  validator_pem "-----BEGIN RSA PRIVATE KEY-----\nMIIEpAIBAAKCAQEAsiGEpeXQhWxfiv+2Oa9OQqkvW+Xo9T3ms9KkE0BjhkWAmqUY\nQLUOvoT/Xi5IGAOfLS49uFJS0Kd6v34JHKB2HR3s6Gno4s/27wV3/RRGGLyGvjTd\nlToTqWu0A2qi/zXTkBJ0H8Qlc6nMnmrpUiTPWN9nqEio1mS1p3FvSWQPistsdaub\n1D1rOSKub7Ht8/AroIOE/U0RudOM9sfj7Cw2BKmnBm8Sj4giRBOBIwEvCF0s8V4u\nFoZWe4Z+QZAsRsVzKlRDsyHOXh+X+UgcGxsGs48i74mhUE02e9UaGQGC8ArlAMuq\nrKkQ5D6C7qcsxqhnrSBBcMFlS9apzfr6qzoszwIDAQABAoIBADjAlRKF9bmMnaQb\ndGNMhxKV9JDC30XDQw1nvv6jNRJCcobSsrdq+BebKAFJnY6JGN28Lc3b7KattV3t\nOdn1BayhLCmgFKKuv23HwELRgsO+zO8syKwSpNEFj4THJMdKzuzH9FdqlsQTBS4z\nwcJ6F9Wo18212JT14SpH6bzoNEtznDGlol/gP2eZ0QF81epL5fDSaB/mcDNjYF0n\nece55i0JDtbbbl7QrLaFXGdQO98FvwmStnB5RHQhPyB/tspjrftK7ShSPBFE3LiR\nBW2o0AfqEOLoASl+luIMRvrmKagbseCAcq032ixr3kvgCjwn6U83Tf2tRAZdbumx\n9R3suQECgYEA2bCD6CJxg5J4ZyuuB4R/vX0+PoZawuZZK+sV8goPvUFYZ6jPgh8V\nI8+3aHlbLhA/KcoeIN4feUy+XiuVN+ZbRjxkfuz4iUIvCV1/QADTQ2IPO0zuB1mx\nlPEDHyzrokzKN4dLkY1wvRiX5s7VufOHuuDNpPbnL7mFOGaD02h+gNkCgYEA0XrI\n5zgjzBdZWfWTAy9FEvWoOw7+qlD7aXl0ERV2V7i70VDxTWuOgywk7+aAfx1ek1h3\nkTPkvmqLE7Sx4/iDYO09JtGL45IFkl4E6XVS+Q9EW5uiBm0YyC3+ZlWowHy87RRx\n713daSAgGlymm97fFnIT3xy6/2JvZF6gjztBkecCgYEAkUttXxzOIwE597KBv2bC\nU9kqGFVYcsmILvYDeb8ZbjoVJWrYxYK1e2eChOqq3v3dCqlqnoli/HUqgnQYbm0D\n8scQVF8aK5LPDjMnYbKrT0g93likbqeBDWYnrUEwLO2P8qwM1iNPYgbuLBFVOX2/\n1A2DdF2PRJ1Qu6pAxnPyK1ECgYEAjgLMYhvoALsvgtH9ySHplPHfC7KdqL7fweBp\ndA91vABrq3pRK+gno/twSwabxBEYBZHq9RAWGZTHFiPgmSjnf/U1CLT0PeHHTzPX\n5qD4EApukCARFoQtUcAEgEG/9kZaGetLVjfvGw6BVP3MoUzVNjU+DXo/t1R3KbcQ\n6CkGya8CgYAGu4WIvH7BMeMyRHf6FQhsiuLoLRlE5Xpwb7hGtWy/9OlLgBWjNDv/\n8uGd28z1Ilsqrs/YVk2+IR2EN4OXZwIqomiXUvPfXE+g/kVG+mZwGmCewZ6uHNVp\nkDga0N9IAbeTjxif6D4nUaXpm5oNbdE2NDIACPOeJhsESAnMSkIRyw==\n-----END RSA PRIVATE KEY-----"

  interface 'eth0' do
    container container_name
    device 'eth0'
    auto true
    address '10.0.3.100'
    gateway '10.0.3.1'
    netmask '255.255.255.0'
  end

  config container_name do
    cap_drop %w(sys_module mac_admin mac_override sys_time)
    mount_entry 'proc proc proc nodev,noexec,nosuid 0 0'
    mount_entry 'sysfs sys sysfs defaults 0 0'
    mount_entry '/sys/fs/fuse/connections sys/fs/fuse/connections none bind,optional 0 0'
    mount_entry '/sys/kernel/debug sys/kernel/debug none bind,optional 0 0'
    mount_entry '/sys/kernel/security sys/kernel/security none bind,optional 0 0'
    mount_entry '/sys/fs/pstore sys/fs/pstore none bind,optional 0 0'
  end
end

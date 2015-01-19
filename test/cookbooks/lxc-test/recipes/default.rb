include_recipe 'minitest-handler'

if(node.platform_family?(:debian))
  include_recipe 'apt'
end

if(node.platform_family?(:rhel))
  include_recipe 'yum-epel'
end

include_recipe 'lxc'

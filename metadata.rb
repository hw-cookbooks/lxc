name             'lxc'
maintainer       'Chris Roberts'
maintainer_email 'chrisroberts.code@gmail.com'
license          'Apache 2.0'
description      'Chef driven Linux Containers'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
## NOTE: bump this out to 2.0. we are hacking out lots of stuffs
version          '1.1.9'

supports 'ubuntu'

suggests 'omnibus_updater'
suggests 'bridger'

depends 'dpkg_autostart', '~> 0.1.10'
depends 'polipo'
depends 'iptables-ng'

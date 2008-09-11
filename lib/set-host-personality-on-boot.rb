#!/usr/bin/env ruby
require 'ec2-instance-data'
require 'register-ddns'

# always set hostname (if it's available)
`hostname "#{EC2InstanceData.user_data['public-hostname']}"` if  EC2InstanceData.user_data.has_key? 'tp-public-hostname'

# set dynamic DNS record if needed
RegisterDDNS.register
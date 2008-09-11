#!/usr/bin/env ruby
require 'ec2-instance-data'
require 'open-uri'

module RegisterDDNS
  AMAZON_INSTANCE_DATA_ADDRESS = "http://169.254.169.254"
  
  def register
    if EC2InstanceData.user_data.has_key?( 'dns-made-easy-record-id')
      ip = open(File.join(AMAZON_INSTANCE_DATA_ADDRESS, '2007-01-19', 'meta-data', 'public-ipv4')).read
      `curl "https://www.dnsmadeeasy.com/servlet/updateip?username=#{ EC2InstanceData.user_data['dns-made-easy-username']}&password=#{ EC2InstanceData.user_data['dns-made-easy-password']}&id=#{ EC2InstanceData.user_data['dns-made-easy-record-id']}&ip=#{ip}"`
    end
  end
  
  module_function :register
end

if __FILE__ == $0
  RegisterDDNS.register
end
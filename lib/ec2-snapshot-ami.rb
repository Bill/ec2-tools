# copyright 2006 Thought Propulsion

require 'ec2-snapshot'
require 'ami-lifecycle'

class EC2SnapshotAmi < EC2Snapshot
  
  private
  
  def lifecycle
    @ami_lifecycle || ( @ami_lifecycle = AmiLifecycle.new( @ec2_user_id, @aws_access_key_id, @aws_secret_access_key, @host_role, @volume_size, @do_tell, @do_debug, @hostname, @ddns_record_id, @do_register_ddns_on_boot) )
  end
  
  def options
    super.concat [
      [ '--hostname', '-h', GetoptLong::OPTIONAL_ARGUMENT],
      [ '--ddns-record-id', '-d', GetoptLong::OPTIONAL_ARGUMENT],
      [ '--register-ddns-on-boot', '-b', GetoptLong::OPTIONAL_ARGUMENT],
    ]
  end
  
  def process_option( opt, arg)
    case opt
      when '--hostname': @hostname = arg
      when '--ddns-record-id': @ddns_record_id = arg
      when '--register-ddns-on-boot': @do_register_ddns_on_boot = (arg.downcase == 'yes' ? true : false )
      else super( opt, arg)
    end
  end
  
  # all my arguments are optional so no checking is necessary here
  # def check_arguments
  # end
  
end

if __FILE__ == $0
  EC2SnapshotAmi.new
end
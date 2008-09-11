require 'lifecycle'

class AmiLifecycle < Lifecycle  

  def initialize( ec2_user_id, aws_access_key_id, aws_secret_access_key, host_role, volume_size, do_tell, do_debug, hostname, ddns_record_id, do_register_ddns_on_boot )
    super( ec2_user_id, aws_access_key_id, aws_secret_access_key, host_role, volume_size, do_tell, do_debug)
    @hostname = hostname
    @ddns_record_id = ddns_record_id
    @do_register_ddns_on_boot = do_register_ddns_on_boot
  end

  def restore_most_recent
    ami_id=`#{ec2_cmd('ec2-describe-images')} | grep #{bucket_base_name} | sort -r -k 3,3 | head -n 1 | cut -f 2`.chomp
    # don't add -k gsg-keypair since it's almost never needed
    run "#{ec2_cmd('ec2-run-instances')} #{ami_id} -g #{@host_role} -d\"#{'tp-public-hostname=' + @hostname + ' tp-ddns-record-id=' + @ddns_record_id + ' tp-register-ddns-on-boot=' + (@do_register_ddns_on_boot ? 'yes' : 'no')}\""
  end
  
  alias start_most_recent restore_most_recent
  
  private 
 
  def outbound_snapshots_directory
    File.join( super, '/ami/')
  end

  def bucket_base_name
    @host_role + '.ami.thoughtpropulsion.com'
  end

  def volume_to_bundle
    '/'
  end

  def upload_bundle( bucket_name)
    super
    run "ec2-register #{bucket_name}/image.manifest"
  end
  
end
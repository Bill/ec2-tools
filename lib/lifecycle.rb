# working_directory               - parent directory of all backup and restore processing
# outbound_snapshots_directory    - parent directory of directories used for outbound staging
# restored_snapshots_directory    - parent directory of directories used for inbound staging
# volume_to_bundle                - input to ec2-bundle-vol
# bundling_directory              - output of ec2-bundle-vol then input to ec2-upload-bundle
# restored_snapshots_staging_area - output of ec2-download-bundle then input to ec2-unbundle 
# restored_images                 - output of ec2-unbundle
# volume_to_restore               - operational (restored) copy of restored volume
# bucket_name                     - S3 bucket name (subclasses customize via bucket_base_name)

class Lifecycle
  
  def initialize( ec2_user_id, aws_access_key_id, aws_secret_access_key, host_role, volume_size, do_tell, do_debug)
    @ec2_user_id = ec2_user_id
    @aws_access_key_id = aws_access_key_id
    @aws_secret_access_key = aws_secret_access_key
    @host_role = host_role
    @timestamp = `date -u '+%Y-%m-%d-%H-%M'`.chomp
    @volume_size = volume_size
    @tell = do_tell
    @debug = do_debug
  end
  
  def snapshot
    destroy_outbound_snapshot_staging_area
    create_outbound_snapshot_staging_area
    create_snapshot_bundle
    unless @debug
      upload_bundle( bucket_name)
      destroy_outbound_snapshot_staging_area
    end
  end

  # subclasses define restore_most_recent.  Not much opportunity for reuse here since
  # the semantics are so different for AMI's versus e.g. svn snapshots
  # def restore_most_recent
  # end

  private
  
  def working_directory
    '/mnt/thoughtpropulsion/'
  end
  
  def outbound_snapshots_directory
    File.join( working_directory, '/outbound-snapshots/')
  end
  
  def destroy_outbound_snapshot_staging_area
    # Cannot remove the directory itself since its parent directory does not give us that permission
    run "rm -fr #{outbound_snapshots_directory}/*"
  end

  def create_outbound_snapshot_staging_area
    run "mkdir -p #{outbound_snapshots_directory}"
  end
  
  # subclasses define bucket_base_name
  # def bucket_base_name
  # end
  
  def bucket_name
    @timestamp + '.' + bucket_base_name
  end
  
  def bundling_directory
    outbound_snapshots_directory
  end
  
  # subclasses define volume_to_bundle
  # def volume_to_bundle
  # end
  
  def create_snapshot_bundle
    # we shouldn't specify -k $EC2_PRIVATE_KEY since we assume private keys are already appended to /root/.ssh/authorized_keys
    # but it's a required parameter -- doh!
    run "#{ec2_cmd('ec2-bundle-vol')} -v #{volume_to_bundle} -d #{bundling_directory} -k $EC2_PRIVATE_KEY -u #{@ec2_user_id} -s #{volume_size}"
  end

  # size of volume (to bundle) in MB
  def volume_size
    # If not user-specified, I'm using a fudge factor of 1.5 on the volume size -- arbitrarily chosen
    @volume_size || (`du -x #{volume_to_bundle}`.split(/\n/)[-1].split[0].to_f * 1.5 / 1024).ceil
  end

  
  def upload_bundle( bucket_name)
    run upload_bundle_command( bucket_name)
  end
  
  def upload_bundle_command( bucket_name)
    "#{ec2_cmd('ec2-upload-bundle')} -b #{bucket_name} -m #{File.join(bundling_directory,'/image.manifest')} -a #{@aws_access_key_id} -s #{@aws_secret_access_key}"
  end
  
  def run( cmd, stdin = nil)
    # TODO: extend run to handle stdin like this perhaps
    if @tell then
      if stdin
        puts "#{cmd} <<here\n#{stdin}\nhere"
      else
        puts cmd
      end
      result = 0
    else
      if stdin
        IO.popen(cmd, 'r+') do |p|
          p.puts( stdin)
        end
      else
        system cmd
      end
      result = $?
    end
    raise "Shell command failed. Command(#{cmd}), Exit Status(#{$?})" unless result == 0
  end
  
  def ec2_cmd(cmd)
    cmd + (@debug && cmd != 'ec2-download-bundle' && cmd != 'ec2-unbundle' ? ' --debug' : '')
  end
end
# copyright 2006 Thought Propulsion

require 'ec2-snapshot'
require 'svn-lifecycle'

class EC2SnapshotSvn < EC2Snapshot
  
  private
  
  def lifecycle
    @svn_lifecycle || ( @svn_lifecycle = SvnLifecycle.new( @ec2_user_id, @aws_access_key_id, @aws_secret_access_key, @host_role, @volume_size, @do_tell, @do_debug) )
  end
  
end

if __FILE__ == $0
  EC2SnapshotSvn.new
end
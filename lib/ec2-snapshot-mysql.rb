# copyright 2006 Thought Propulsion

require 'ec2-snapshot'
require 'mysql-lifecycle'

class EC2SnapshotMySQL < EC2Snapshot
  
  private
  
  def lifecycle
    @mysql_lifecycle || ( @mysql_lifecycle = MySQLLifecycle.new( @ec2_user_id, @aws_access_key_id, @aws_secret_access_key, @host_role, @volume_size, @do_tell, @do_debug, @database_username, @database_password) )
  end
  
  def options
    super.concat [
      [ '--database-username', GetoptLong::OPTIONAL_ARGUMENT],
      [ '--database-password', GetoptLong::OPTIONAL_ARGUMENT],
    ]
  end
  
  def process_option( opt, arg)
    case opt
      when '--database-username': @database_username = arg
      when '--database-password': @database_password = arg
      else super( opt, arg)
    end
  end
  
  def check_arguments
    super
    if( @do_snapshot && !( @database_username || @database_password) )
      raise ArgumentError, "Missing command line parameters: both --database-username and --database-password are required"
    end
  end
  
  def usage_instructions
    super +
      " --database-username some-username --database-password some-password"
  end
end

if __FILE__ == $0
  EC2SnapshotMySQL.new
end
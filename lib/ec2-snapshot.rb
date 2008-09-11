# copyright 2006 Thought Propulsion

require 'getoptlong'

class EC2Snapshot
  
  def initialize
    begin
      opts = GetoptLong.new( * options())

      opts.each do | opt, arg|
        process_option( opt, arg)
      end
  
      check_arguments

      do_command

    rescue Exception
      $stderr.puts "Error: " + $!
      $stderr.puts usage_instructions
    end
  end
  
  private
  
  # subclass may extend this array
  def options
    [
      [ '--ec2-user-id', '-u', GetoptLong::REQUIRED_ARGUMENT],
      [ '--aws-access-key-id', '-a', GetoptLong::REQUIRED_ARGUMENT],
      [ '--aws-secret-access-key', '-s', GetoptLong::REQUIRED_ARGUMENT],
      [ '--snapshot', GetoptLong::NO_ARGUMENT],
      [ '--restore-most-recent', '--start-most-recent', GetoptLong::NO_ARGUMENT],
      [ '--host-role', '-r', GetoptLong::REQUIRED_ARGUMENT],
      [ '--volume-size', GetoptLong::OPTIONAL_ARGUMENT],
      [ '--tell', GetoptLong::NO_ARGUMENT],
      [ '--debug', GetoptLong::NO_ARGUMENT]
    ]
  end
  
  # subclass may extend this: handle options and delegate to super in "else" clause
  def process_option( opt, arg)
    case opt
      when '--ec2-user-id': @ec2_user_id = arg
      when '--aws-access-key-id': @aws_access_key_id = arg
      when '--aws-secret-access-key': @aws_secret_access_key = arg
      when '--snapshot': @do_snapshot = true
      when '--restore-most-recent': @do_restore = true
      when '--host-role': @host_role = arg
      when '--volume-size': @volume_size = arg
      when '--tell': @do_tell = true
      when '--debug': @do_debug = true
    end
  end
  
  # subclass may extend this (override and call super)
  def check_arguments
    if (@ec2_user_id.nil? || @aws_access_key_id.nil? || @aws_secret_access_key.nil? || @host_role.nil? || ! ( @do_snapshot || @do_restore )) then
      raise ArgumentError, "Missing command line parameter"
    end
  end
  
  # subclass may extend this (override and call super)
  def usage_instructions
    "Usage: #{$0} (--ec2-user-id | -u) (--aws-access-key-id | -a) (--aws-secret-access-key | -s) (--host_role | -r) (--snapshot | (--restore-most-recent | --start-most-recent) ) [--volume-size] [--tell] [--debug]"
  end

  # Subclass should supply this  
  def lifecycle
    raise "No definition of 'lifecycle' -- subclass should supply definition"
  end
  
  def do_command
    if @do_snapshot then
      lifecycle().snapshot
    elsif @do_restore then
      lifecycle().restore_most_recent
    end
  end
  
end
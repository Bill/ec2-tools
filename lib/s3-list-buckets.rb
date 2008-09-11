# copyright 2006 Thought Propulsion

require 'getoptlong'
require 'S3'
require 'time'

class S3ListBuckets
  def initialize( aws_access_key_id, aws_secret_access_key)
    @aws_access_key_id = aws_access_key_id
    @aws_secret_access_key = aws_secret_access_key
  end
  
  def buckets
    @conn = S3::AWSAuthConnection.new(@aws_access_key_id, @aws_secret_access_key)
    response = @conn.list_all_my_buckets()
    response.entries
  end
end

if __FILE__ == $0
  begin
    opts = GetoptLong.new(
      [ '--aws-access-key-id', '-a', GetoptLong::REQUIRED_ARGUMENT],
      [ '--aws-secret-access-key', '-s', GetoptLong::REQUIRED_ARGUMENT],
      [ '--tell', GetoptLong::NO_ARGUMENT],
      [ '--debug', GetoptLong::NO_ARGUMENT]
    )

    opts.each do | opt, arg|
      case opt
      when '--aws-access-key-id': $aws_access_key_id = arg
      when '--aws-secret-access-key': $aws_secret_access_key = arg
      when '--tell': $do_tell = true
      when '--debug': $do_debug = true
      end
    end

    if ($aws_access_key_id.nil? || $aws_secret_access_key.nil?) then
      raise ArgumentError, "Missing command line parameter"
    end

    lister = S3ListBuckets.new( $aws_access_key_id, $aws_secret_access_key)
    lister.buckets.sort{|a,b| Time.xmlschema(a.creation_date) <=> Time.xmlschema(b.creation_date)}.each{ |b| puts b.name + ' ' + b.creation_date}    
  rescue Exception
    $stderr.puts "Error: " + $!
    $stderr.puts "Usage: #{$0} (--aws-access-key-id | -a) (--aws-secret-access-key | -s) [--tell] [--debug]"
  end
  
end
require 'lifecycle'
require 's3-list-buckets'
require 'aes/amiutil/image'

class MySQLLifecycle < Lifecycle  

  def initialize( ec2_user_id, aws_access_key_id, aws_secret_access_key, host_role, volume_size, do_tell, do_debug, database_username, database_password )    
    super( ec2_user_id, aws_access_key_id, aws_secret_access_key, host_role, volume_size, do_tell, do_debug)
    @database_username = database_username
    @database_password = database_password
  end

  def restore_most_recent
    begin
      # stop the database server
      run "/etc/init.d/mysqld stop"

      # preserve old local repository and move it out of the way
      old = `mktemp -d`.chomp
      run "mv #{mysql_files} #{old}"

      # extra cleanup in case we were stopped in the middle last time
      destroy_inbound_snapshot_staging_area
      
      run "mkdir -p #{restored_snapshots_staging_area}"
      run "mkdir -p #{restored_images}"
      
      latest_bucket_name = S3ListBuckets.new( @aws_access_key_id, @aws_secret_access_key).buckets.sort{|a,b| Time.xmlschema(a.creation_date) <=> Time.xmlschema(b.creation_date)}.find_all{|b| b.name =~ Regexp.compile( '.*' + Regexp.escape(bucket_base_name))}.last.name
      
      run "#{ec2_cmd('ec2-download-bundle')} -b #{latest_bucket_name} -m image.manifest -a #{@aws_access_key_id} -s #{@aws_secret_access_key} -k $EC2_PRIVATE_KEY -d #{restored_snapshots_staging_area}"
      
      run "#{ec2_cmd('ec2-unbundle')} -m #{File.join(restored_snapshots_staging_area, 'image.manifest.plaintext')} -s #{ restored_snapshots_staging_area} -d #{restored_images}"

      # Break in to Amazon's Image class
      Image.module_eval( %q{ public :mount_image, :copy_rec, :cleanup})
      
      # If we simply mounted this image, then when we did a bunch of svn adds/imports we'd quickly run out of space.
      # So we recreate the hierarchy in main filesystem (on black.thoughtpropulsion.com it's /dev/sda1), then unmount the image.
      # Third parameter doesn't matter for unbundling (mb_image_size).
      # Fourth parameter is a list of directories to exclude
      img = Image.new( volume_to_restore, File.join( restored_images, "image.img"), 1, ["/mnt", "/proc", "/sys", "/dev", "/lost+found", "/etc"])
      img.mount_image
      # I wish this internal routine didn't require me to re-submit the init parameters
      # Exclude superfluous stuff put in by ec2-bundle-vol (Image.make_special_dirs) plus
      # those created by Image.create_image_file
      # NB: trailing slash is pertinent to Image class -- make sure we have a trailing slash!!!
      img.copy_rec( Image::IMG_MNT, volume_to_restore + File::Separator )
      
      link_to_restored_volume
      
      img.cleanup unless @debug
    rescue
      $stderr.print "#{$0} failed: #{$!}"
      # revert to old local repository
      run "mv #{File.join( old, File.basename(volume_to_restore))} #{volume_to_restore}"
      link_to_restored_volume
    ensure
      unless @debug
        run "rm -fr #{old}"
        destroy_inbound_snapshot_staging_area
      end
    end
    
  end

  private 
  
  def link_to_restored_volume
    # start the database server
    run "/etc/init.d/mysqld start"

    # database dump is in #{volume_to_restore} so now we need to load it into the database
    run( "mysql < #{File.join( volume_to_restore, snapshot_filename)}")
    
    # we have to tell the server to flush permissions in order for password protection to be inforce
    run "mysql", "FLUSH PRIVILEGES"
  end
  
  def destroy_inbound_snapshot_staging_area
    run "rm -fr #{restored_snapshots_staging_area}"
    run "rm -fr #{restored_images}"
    run "rmdir #{Image::IMG_MNT}"

    # blow away the restored SQL dump file -- we don't need it anymore
    run "rm -fr #{volume_to_restore}"
  end
 
  def outbound_snapshots_directory
    File.join( super, '/mysql/')
  end

  def restored_snapshots_directory
    File.join( working_directory, '/restored-snapshots/mysql/')
  end

  def restored_snapshots_staging_area
    File.join( restored_snapshots_directory, '/bundle/')
  end

  def restored_images
    File.join( restored_snapshots_directory, '/image/')
  end

  def bucket_base_name
    'mysql.complete.1.'+ @host_role + '.working-data-snapshot.thoughtpropulsion.com'
  end
  
  def volume_to_bundle
    "#{File.join(outbound_snapshots_directory,'/volume')}"
  end
  
  def volume_to_restore
    File.join( restored_snapshots_directory, 'volume')
  end

  def mysql_files
    File.join( restored_snapshots_directory, 'mysql')
  end
  
  def bundling_directory
    File.join( super, '/bundle')
  end

  def create_outbound_snapshot_staging_area
    super
    run "mkdir -p #{volume_to_bundle}"
    run "mkdir -p #{bundling_directory}"
  end

  def create_snapshot_bundle
    run "mysqldump -u #{@database_username} -p#{@database_password} --single-transaction --all-databases > #{File.join( volume_to_bundle, snapshot_filename)}"
    super
  end
  
  def snapshot_filename
    'mysql_complete_backup.sql'
  end

  # override Amazon's certificate with my own
  def upload_bundle_command( bucket_name)
    super + ' --ec2certificate $EC2_CERT'
  end
  
  # augh -- ec2-upload-bundle requires user interaction to confirm certificate override!
  def upload_bundle( bucket_name)
    if @tell then
      # if we're just echoing the command (not really running it then let super take over)
      super
    else
      IO.popen( upload_bundle_command( bucket_name), 'r+') {|pipe| 
        pipe.puts 'y'
        pipe.flush
        pipe.close_write
        puts pipe.readlines 
        }
    end
  end
end
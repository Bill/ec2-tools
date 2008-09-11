require 'lifecycle'
require 's3-list-buckets'
require 'aes/amiutil/image'

class SvnLifecycle < Lifecycle
  
  def restore_most_recent
    begin
      # preserve old local repository and move it out of the way
      old = `mktemp -d`.chomp
      run "mv #{volume_to_restore} #{old}"

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
      img.copy_rec( Image::IMG_MNT, volume_to_restore )
      run "chown svn:svn #{volume_to_restore}"
      
      link_to_restored_volume
      
      img.cleanup unless @debug
    rescue
      $stderr.print "#{$0} failed: #{$!}"
      # revert to old local repository
      run "mv #{File.join( old, File.basename(volume_to_restore))} #{volume_to_restore}"
      link_to_restored_volume # repair broken link
    ensure
      unless @debug
        run "rm -fr #{old}"
        destroy_inbound_snapshot_staging_area
      end
    end
    
  end

  private 
  
  def link_to_restored_volume
    # Link from ~svn/repository to the restored volume -- this is where svn wants the repository to appear
    # Note that permissions on the link don't matter -- permissions on the actual file/dir are in effect
    run "ln -s #{volume_to_restore} ~svn/repository"
  end
  
  def destroy_inbound_snapshot_staging_area
    run "rm -fr #{restored_snapshots_staging_area}"
    run "rm -fr #{restored_images}"
    run "rmdir #{Image::IMG_MNT}"
  end
 
  def outbound_snapshots_directory
    File.join( super, '/svn/')
  end

  def restored_snapshots_directory
    File.join( working_directory, '/restored-snapshots/svn/')
  end

  def restored_snapshots_staging_area
    File.join( restored_snapshots_directory, '/bundle/')
  end

  def restored_images
    File.join( restored_snapshots_directory, '/image/')
  end

  def bucket_base_name
    'svn.1.'+ @host_role + '.working-data-snapshot.thoughtpropulsion.com'
  end
  
  def volume_to_bundle
    "#{File.join(outbound_snapshots_directory,'/volume')}"
  end
  
  def volume_to_restore
    File.join( restored_snapshots_directory, '/repository/')
  end
  
  def bundling_directory
    File.join( super, '/bundle')
  end

  def create_outbound_snapshot_staging_area
    super
    run "mkdir -p #{volume_to_bundle}"
    run "chown svn:svn #{volume_to_bundle}"
    run "mkdir -p #{bundling_directory}"
  end

  def create_snapshot_bundle
    run "sudo -u svn svnadmin hotcopy #{volume_to_restore} #{volume_to_bundle}"
    super
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
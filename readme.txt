working_directory               - parent directory of all backup and restore processing
outbound_snapshots_directory    - parent directory of directories used for outbound staging
restored_snapshots_directory    - parent directory of directories used for inbound staging
volume_to_bundle                - input to ec2-bundle-vol
bundling_directory              - output of ec2-bundle-vol then input to ec2-upload-bundle
restored_snapshots_staging_area - output of ec2-download-bundle then input to ec2-unbundle 
restored_images                 - output of ec2-unbundle
volume_to_restore               - operational (restored) copy of restored volume
bucket_name                     - S3 bucket name (subclasses customize via bucket_base_name)


lifecycle.rb - abstract base class

bucket_name =						@timestamp + '.' (subclass override)
working_directory = 				/mnt/thoughtpropulsion/
outbound_snapshots_directory =		/mnt/thoughtpropulsion/outbound-snapshots/
 a.k.a. outbound_snapshot_staging_area
 a.k.a. bundling_directory


ami-lifecycle.rb - lifecycle for Amazon AMI

bucket_base_name =					@timestamp + '.' + @host_role + '.ami.thoughtpropulsion.com'
outbound_snapshots_directory = 		/mnt/thoughtpropulsion/outbound-snapshots/ami
volume_to_bundle =					/


svn-lifecycle.rb - lifecycle for Subversion repository

bucket_base_name =					@timestamp + '.' + svn.1.'+ @host_role + '.working-data-snapshot.thoughtpropulsion.com'
outbound_snapshots_directory = 		/mnt/thoughtpropulsion/outbound-snapshots/svn
volume_to_bundle =					/mnt/thoughtpropulsion/outbound-snapshots/svn/volume
bundling_directory = 				/mnt/thoughtpropulsion/outbound-snapshots/svn/bundle
restored_snapshots_directory = 		/mnt/thoughtpropulsion/restored-snapshots/svn
restored_snapshots_staging_area = 	/mnt/thoughtpropulsion/restored-snapshots/svn/bundle
restored_images =					/mnt/thoughtpropulsion/restored-snapshots/svn/image
volume_to_restore =					/mnt/thoughtpropulsion/restored-snapshots/svn/repository


mysql-lifecycle.rb - lifecycle for mySQL database

bucket_base_name =					@timestamp + '.' + 'mysql.complete.1.'+ @host_role + '.working-data-snapshot.thoughtpropulsion.com'
outbound_snapshots_directory =		/mnt/thoughtpropulsion/outbound-snapshots/mysql
volume_to_bundle =					/mnt/thoughtpropulsion/outbound-snapshots/mysql/volume
bundling_directory =				/mnt/thoughtpropulsion/outbound-snapshots/mysql/bundle
restored_snapshots_directory = 		/mnt/thoughtpropulsion/restored-snapshots/mysql
restored_snapshots_staging_area = 	/mnt/thoughtpropulsion/restored-snapshots/mysql/bundle
restored_images =					/mnt/thoughtpropulsion/restored-snapshots/mysql/image
volume_to_restore = 				/mnt/thoughtpropulsion/restored-snapshots/mysql/volume
mysql_files = 						/mnt/thoughtpropulsion/restored-snapshots/mysql/mysql_

require 'open-uri'

module EC2InstanceData
  
  def user_data()
    result = Hash.new
    open 'http://169.254.169.254/2007-01-19/user-data' do | launch_parameters |
    	launch_parameters.gets.chomp.split( ' ').each do | parameter | 
    		pair = parameter.split('=')
    		result[ pair[0]] = (pair.length > 1 ? pair[1] : nil)
    	end
    end
    result
  end
  
  module_function :user_data
end
class Person < ActiveRecord::Base
	include Rhoconnectrb::Resource

	# RhoConnect default partition
	def partition
  	:app
  end

  def self.rhoconnect_query(partition)
    includes(:address, :email).all
  end
end

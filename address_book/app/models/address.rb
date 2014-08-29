class Address < ActiveRecord::Base
  include Rhoconnectrb::Resource

  # RhoConnect partition
  def partition
    :app
  end

  def self.rhoconnect_query(partition, options={})
    all
  end
end

class Email < ActiveRecord::Base
  belongs_to :person

  # RhoConnect partition
  def partition
  	lambda { self.user.name }
  end

  def self.rhoconnect_query(partition)
    Email.includes(:user).where("users.username = ?", partition)
  end
end

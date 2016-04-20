require "shoppe/notification/version"
require "shoppe/notification/engine"

module Shoppe
  module Notification
  	def self.setup
	  Shoppe::Order.before_confirmation do
	   Shoppe::NotificationMailer.order_received(self).deliver_now
  	end
end
  end
end

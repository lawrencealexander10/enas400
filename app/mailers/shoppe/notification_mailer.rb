module Shoppe
  class NotificationMailer < ActionMailer::Base

    def order_received(order)
      @order = order
      staff = Shoppe::User.all.map(&:email_address)
      mail from: Shoppe.settings.outbound_email_address, to: staff, subject: "New Order Received"
    end

  end
end
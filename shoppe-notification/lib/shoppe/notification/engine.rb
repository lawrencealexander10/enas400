module Shoppe
  module Notification
    class Engine < Rails::Engine

      initializer "shoppe.notification.initializer" do
        Shoppe::Notification.setup
      end

    end
  end
end
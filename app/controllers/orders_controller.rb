class OrdersController < ApplicationController

	 before_filter(:except => :status) { redirect_to root_path unless has_order? }

  def destroy
    current_order.destroy
    session[:order_id] = nil
    respond_to do |wants|
      wants.html { redirect_to root_path, :notice => "Your basket has been emptied successfully."}
      wants.json do
        flash[:notice] = "Your shopping bag is now empty."
        render :json => {:status => 'complete', :redirect => root_path}
      end
    end
  end
	
	def checkout
	  @order = Shoppe::Order.find(current_order.id)
	  if request.patch?
	    if @order.proceed_to_confirm(params[:order].permit(:first_name, :last_name, :billing_address1, :billing_address2, :billing_address3, :billing_address4, :billing_country_id, :billing_postcode, :email_address, :phone_number))
	      redirect_to checkout_payment_path
	    end
	  end
	end

def payment
  @order = Shoppe::Order.find(session[:order_id])
  if request.post?
    if @order.accept_stripe_token(params[:stripe_token])
      redirect_to checkout_confirmation_path
    else
      flash.now[:notice] = "Could not exchange Stripe token. Please try again."
    end
  end
end	

	def confirmation
	  if request.post?
	    current_order.confirm!
	    session[:order_id] = nil
	    redirect_to root_path, :notice => "Order has been placed successfully!"
	  end
	end

	def remove_item
	    item = current_order.order_items.find(params[:order_item_id])
	    if current_order.order_items.count == 1
	      destroy
	    else
	      item.remove
	      respond_to do |wants|
	        wants.html { redirect_to request.referer, :notice => "Item has been removed from your basket successfully"}
	        wants.json do
	          current_order.reload
	          render :json => {:status => 'complete', :items => render_to_string(:partial => 'shared/order_items.html', :locals => {:order => current_order})}
	        end
	      end
	    end
	  end

	def change_item_quantity
		item = current_order.order_items.find(params[:order_item_id])
		request.delete? ? item.decrease! : item.increase!
		respond_to do |wants|
		  wants.html { redirect_to request.referer || root_path, :notice => "Quantity has been updated successfully." }
		  wants.json do
		    current_order.reload
		    if current_order.empty?
		      destroy
		    else
		      render :json => {:status => 'complete', :items => render_to_string(:partial => 'shared/order_items.html', :locals => {:order => current_order})}
		    end
		  end
		end    
		rescue Shoppe::Errors::NotEnoughStock => e
		respond_to do |wants|
		  wants.html { redirect_to request.referer, :alert => "Unfortunately, we don't have enough stock. We only have #{e.available_stock} items available at the moment. Please get in touch though, we're always receiving new stock." }
		  wants.json { render :json => {:status => 'error', :message => "Unfortunateley, we don't have enough stock to add more items."} }
		end
	end

	  def change_delivery_service
    if current_order.delivery_service = current_order.available_delivery_services.select { |s| s.id == params[:delivery_service].to_i}.first
      current_order.save
      respond_to do |wants|
        wants.html { redirect_to request.referer, :notice => "Delivery service has been changed"}
        wants.json do
          current_order.reload
          render :json => {:status => 'complete', :items => render_to_string(:partial => 'shared/order_items.html', :locals => {:order => current_order})}
        end
      end
    else
      respond_to do |wants|
        wants.html { redirect_to request.referer, :alert => "You cannot select this delivery method."}
        wants.json { render :json => {:status => 'error', :message => 'InvalidDeliveryMethod'}, :status => 422 }
      end
    end
  end

end

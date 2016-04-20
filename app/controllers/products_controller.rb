class ProductsController < ApplicationController

  def index
    @products = Shoppe::Product.active.includes(:product_categories, :variants).root
    @products = @products.group_by(&:product_category)
  end

  def show
    @product = Shoppe::Product.root.find_by_permalink(params[:permalink])
    @product_attributes = Shoppe::ProductAttribute.where(product_id: @product.id)
    respond_to do |format|
        format.html
        format.json { render :json => {:product => @product, :attributes => @product_attributes}  }
    end
  end

	def buy
	  @product = Shoppe::Product.root.find_by_permalink!(params[:permalink])
	  current_order.order_items.add_item(@product, 1)
	  redirect_to :back , :notice => "Product has been added successfuly!"
	    rescue Shoppe::Errors::NotEnoughStock => e
    respond_to do |wants|
      wants.html { redirect_to request.referer, :alert => "We're sorry but we don't have enough stock to add that many products. We currently have #{e.available_stock} item(s) in stock. Please try again."}
      wants.json { render :json => {:error => 'NotEnoughStock', :available_stock => e.available_stock}}
    end
	end
end
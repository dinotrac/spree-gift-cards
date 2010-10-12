class GiftCardsController < Spree::BaseController
  helper 'admin/base'
  def new
    find_gift_card_variants
    @gift_card = GiftCard.new
  end
  
  def create
    @gift_card = GiftCard.new(params[:gift_card])
    if @gift_card.save
      @order = current_order(true)
      line_item = @order.add_variant(@gift_card.variant, 1)
      @gift_card.update_attributes(:line_item => line_item, :user => current_user)
      redirect_to cart_path
    else
      find_gift_card_variants
      render :action => :new
    end
  end
  
  def activate
    @gift_card = GiftCard.find_by_token(params[:id])
    if @gift_card.is_received
      flash[:error] = "You can't activate this gift card, b/c it was already activated."
      redirect_to root_url
      return
    else
      @gift_card.update_attribute(:is_received, true)
    end
    if current_user && !current_user.anonymous?
      if @gift_card.register(current_user)
        flash[:notice] = "Gift card activated, now you have store credit and can use it to pay for purchases in full or in part"
      else
        flash[:error] = "Couldn't register gift card"
      end
    else
      session[:gift_card] = @gift_card.token
      flash[:notice] = "To use gift card you should sign up or log in if you're already registered."      
    end
    redirect_to root_url
  end
  
  private
  
  def find_gift_card_variants
    gift_card_product_ids = Product.not_deleted.where(["is_gift_card = ?", true]).map(&:id)
    @gift_card_variants = Variant.where(["price > 0 AND product_id IN (?)", gift_card_product_ids]).order("price")
  end
end
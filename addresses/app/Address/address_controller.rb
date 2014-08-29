require 'rho/rhocontroller'
require 'helpers/browser_helper'

class AddressController < Rho::RhoController
  include BrowserHelper

  # GET /Address
  def index
    @addresses = Address.find(:all)
    render :back => '/app'
  end

  # GET /Address/{1}
  def show
    @address = Address.find(@params['id'])
    if @address
      render :action => :show, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # GET /Address/new
  def new
    @address = Address.new
    render :action => :new, :back => url_for(:action => :index)
  end

  # GET /Address/{1}/edit
  def edit
    @address = Address.find(@params['id'])
    if @address
      render :action => :edit, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # POST /Address/create
  def create
    @address = Address.create(@params['address'])
    redirect :action => :index
  end

  # POST /Address/{1}/update
  def update
    @address = Address.find(@params['id'])
    @address.update_attributes(@params['address']) if @address
    redirect :action => :index
  end

  # POST /Address/{1}/delete
  def delete
    @address = Address.find(@params['id'])
    @address.destroy if @address
    redirect :action => :index  
  end
end

class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home ]

  def home
    @origin = [-23.5648, -46.6518]
    @destination = [0, 0]
    @destin = Destination.new
  end

  def index
  end
end

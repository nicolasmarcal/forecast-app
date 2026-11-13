class ForecastsController < ApplicationController
  def new
    @forecast_request = ForecastRequest.new
  end

  def create
    @forecast_request = ForecastRequest.new(forecast_params)

    if @forecast_request.valid?
      @forecast_data = WeatherService.new(@forecast_request.zip_code).call

    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def forecast_params
    params.require(:forecast_request).permit(:zip_code)
  end
end

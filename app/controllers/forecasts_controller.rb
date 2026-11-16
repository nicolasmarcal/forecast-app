class ForecastsController < ApplicationController
  def new
    @forecast_request = ForecastRequest.new
  end

  def create
    @forecast_request = ForecastRequest.new(forecast_params)

    unless @forecast_request.valid?
      return respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            "forecast_form",
            partial: "form",
            locals: { forecast_request: @forecast_request }
          ), status: :unprocessable_content
        end
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: { errors: @forecast_request.errors.full_messages }, status: :unprocessable_content }
      end
    end

    @forecast_data = WeatherService.new(@forecast_request.zip_code).call

    respond_to do |format|
      format.turbo_stream
      format.html { render :new }
      format.json do
        if @forecast_data[:error].present?
          render json: { error: @forecast_data[:error] }, status: :bad_gateway
        else
          render json: {
            zip_code: @forecast_data[:zip_code],
            temperature: @forecast_data.dig(:data, :temp),
            high: @forecast_data.dig(:data, :high),
            low: @forecast_data.dig(:data, :low),
            from_cache: @forecast_data[:from_cache]
          }, status: :ok
        end
      end
    end
  end

  private

  def forecast_params
    if params[:forecast_request].present?
      params.require(:forecast_request).permit(:zip_code)
    else
      params.permit(:zip_code)
    end
  end
end

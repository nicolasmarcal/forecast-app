class ForecastsController < ApplicationController
  protect_from_forgery with: :null_session, if: -> { request.format.json? }

  def new
    @forecast_request = ForecastRequest.new
  end

  def show
    create
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
      format.turbo_stream { render :create, status: @forecast_data.http_status }
      format.html { render :new, status: @forecast_data.http_status }
      format.json do
        if @forecast_data.success?
          render json: serialize_forecast(@forecast_data), status: :ok
        else
          render json: { error: @forecast_data.error_message }, status: @forecast_data.http_status
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

  def serialize_forecast(result)
    {
      zip_code: result.zip_code,
      temperature: result.temperature,
      high: result.high,
      low: result.low,
      from_cache: result.from_cache
    }
  end
end

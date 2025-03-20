# app/services/ride_price_service.rb
class RidePriceService
  def initialize(distance_km, duration_minutes)
    @distance_km = distance_km
    @duration_minutes = duration_minutes
    @client = OpenAI::Client.new
  end

  # Preço para a viagem completa (Uber ou 99)
  def fetch_full_ride_price(provider)
    prompt = "Dê o valor padrão de uma corrida de #{provider} para uma distância de #{@distance_km} km e uma duração de #{@duration_minutes} minutos em São Paulo, Brasil. Retorne apenas o valor numérico em reais, no formato R$ XX,XX (ex.: R$ 20,15), sem qualquer texto adicional."
    response = @client.chat(parameters: {
                              model: "gpt-4o-mini",
                              messages: [{ role: "user", content: prompt }],
                              temperature: 0.7
                            })
    price = response["choices"][0]["message"]["content"]
    # Converter o preço para float (ex.: "R$ 20,15" -> 20.15)
    price.gsub("R$ ", "").gsub(",", ".").to_f
  end

  # Preço para a viagem até a estação de metrô (Uber)
  def fetch_uber_to_station_price(station_distance_km, station_duration_minutes)
    prompt = "Dê o valor padrão de uma corrida de Uber para uma distância de #{station_distance_km} km e uma duração de #{station_duration_minutes} minutos em São Paulo, Brasil. Retorne apenas o valor numérico em reais, no formato R$ XX,XX (ex.: R$ 20,15), sem qualquer texto adicional."
    response = @client.chat(parameters: {
                              model: "gpt-4o-mini",
                              messages: [{ role: "user", content: prompt }],
                              temperature: 0.7
                            })
    price = response["choices"][0]["message"]["content"]
    # Converter o preço para float (ex.: "R$ 20,15" -> 20.15)
    price.gsub("R$ ", "").gsub(",", ".").to_f
  end
end

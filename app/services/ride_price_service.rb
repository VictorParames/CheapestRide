# app/services/ride_price_service.rb
class RidePriceService
  def initialize(distance_km, duration_minutes)
    @distance_km = distance_km.to_f # Garantir que seja Float
    @duration_minutes = duration_minutes.to_f # Garantir que seja Float
    @client = OpenAI::Client.new
  end

  def fetch_full_ride_price(provider)
    # Ajustar o prompt para incluir instruções específicas sobre as tarifas de cada provedor
    prompt = case provider
             when "Uber"
               "Dê o valor padrão de uma corrida de Uber para uma distância de #{@distance_km} km e uma duração de #{@duration_minutes} minutos em São Paulo, Brasil. Considere tarifas realistas para o mercado atual: taxa base de R$ 5,00, R$ 2,50 por km e R$ 0,60 por minuto, além de possíveis taxas adicionais. Retorne apenas o valor numérico em reais, no formato R$ XX,XX (ex.: R$ 20,15), sem qualquer texto adicional."
             when "99"
               "Dê o valor padrão de uma corrida de 99 para uma distância de #{@distance_km} km e uma duração de #{@duration_minutes} minutos em São Paulo, Brasil. Considere tarifas realistas para o mercado atual: taxa base de R$ 4,50, R$ 2,30 por km e R$ 0,55 por minuto, além de possíveis taxas adicionais. Retorne apenas o valor numérico em reais, no formato R$ XX,XX (ex.: R$ 20,15), sem qualquer texto adicional."
             when "InDrive"
               "Dê o valor padrão de uma corrida de InDrive para uma distância de #{@distance_km} km e uma duração de #{@duration_minutes} minutos em São Paulo, Brasil. Considere tarifas realistas para o mercado atual: taxa base de R$ 4,00, R$ 2,00 por km e R$ 0,50 por minuto, além de possíveis taxas adicionais. InDrive geralmente é mais barato que Uber e 99. Retorne apenas o valor numérico em reais, no formato R$ XX,XX (ex.: R$ 20,15), sem qualquer texto adicional."
             else
               "Dê o valor padrão de uma corrida de #{provider} para uma distância de #{@distance_km} km e uma duração de #{@duration_minutes} minutos em São Paulo, Brasil. Considere tarifas realistas para o mercado atual, incluindo taxas base, preço por km e preço por minuto. Retorne apenas o valor numérico em reais, no formato R$ XX,XX (ex.: R$ 20,15), sem qualquer texto adicional."
             end

    Rails.logger.info("Fetching price for #{provider} with prompt: #{prompt}")
    begin
      response = @client.chat(parameters: {
        model: "gpt-4o-mini",
        messages: [{ role: "user", content: prompt }],
        temperature: 0.7
      })
      price = response["choices"][0]["message"]["content"]
      Rails.logger.info("ChatGPT response for #{provider}: #{price}")
      # Converter o preço para float (ex.: "R$ 20,15" -> 20.15)
      price_value = price.gsub("R$ ", "").gsub(",", ".").to_f
      # Validar o preço (mínimo de R$ 5,00 para evitar valores irrealistas)
      if price_value < 5.0
        Rails.logger.warn("Unrealistic price for #{provider}: #{price_value}. Using fallback.")
        calculate_fallback_price(provider)
      else
        price_value
      end
    rescue StandardError => e
      Rails.logger.error("Failed to fetch price for #{provider}: #{e.message}")
      calculate_fallback_price(provider)
    end
  end

  private

  def calculate_fallback_price(provider)
    # Definir tarifas diferenciadas para cada provedor
    case provider
    when "Uber"
      base_price = 5.0
      price_per_km = 2.5
      price_per_minute = 0.6
    when "99"
      base_price = 4.5
      price_per_km = 2.3
      price_per_minute = 0.55
    when "InDrive"
      base_price = 4.0
      price_per_km = 2.0
      price_per_minute = 0.5
    else
      base_price = 5.0
      price_per_km = 2.0
      price_per_minute = 0.5
    end

    total_price = base_price + (price_per_km * @distance_km) + (price_per_minute * @duration_minutes)
    Rails.logger.info("Fallback price for #{provider}: R$ #{total_price.round(2)}")
    total_price.round(2)
  end
end

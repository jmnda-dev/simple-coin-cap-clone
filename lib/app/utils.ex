defmodule App.Utils.CoinDataFetcher do
  require Logger
  @coincap_base_url "https://api.coincap.io/v2/assets/"

  def get_coin_history(id, interval) do
    case fetch_history(id, interval) do
      {:ok, data} ->
        clean_data(data) |> create_plot_data(interval)

      :error ->
        nil
    end
  end

  defp fetch(url) do
    HTTPoison.get!(url)
  end

  defp fetch_history(coin_id, interval) do
    url = "#{@coincap_base_url}/#{coin_id}/history?interval=#{interval}"

    with %{body: body, status_code: 200} <-
           fetch(url),
         {:ok, %{"data" => data}} = Jason.decode(body) do
      {:ok, data}
    else
      %{status_code: status_code} ->
        Logger.error("An error ouccured, status_code: #{status_code}")
        :error

      {:error, %{reason: reason}} ->
        Logger.error("An error occured, reason: #{reason}")
        :error
    end
  end

  defp clean_data(data) do
    Enum.map(
      data,
      fn item ->
        time = to_readable_time(item["date"])
        Map.put(item, "time", time)
      end
    )
  end

  defp to_readable_time(datetime_string) do
    {:ok, datetime, _} = DateTime.from_iso8601(datetime_string)

    datetime
    |> DateTime.to_time()
    |> Time.to_string()
    |> String.replace_suffix(":00.000", "")
  end

  defp create_plot_data(data, interval) do
    Enum.reduce(
      data,
      %{x: [], y: []},
      fn item, acc ->
        %{acc | x: [item["priceUsd"] | acc.x], y: [item["time"] | acc.y]}
      end
    )
    |> Enum.map(fn {key, value} -> {key, Enum.reverse(value)} end)
    |> Enum.into(%{})
    |> take_items(interval)
  end

  defp take_items(%{x: x, y: y}, interval) when interval in ["m1", "m5", "m15"] do
    %{x: Enum.take(x, -40), y: Enum.take(y, -40)}
  end

  defp take_items(%{x: x, y: y}, interval) when interval == "m30" do
    %{x: Enum.take(x, -48), y: Enum.take(y, -48)}
  end

  defp take_items(%{x: x, y: y}, interval) when interval in ["h1", "h2", "h6", "h12"] do
    %{x: Enum.take(x, -24), y: Enum.take(y, -24)}
  end
end

defmodule App.CoinDataWorker do
  use GenServer
  require Logger
  alias AppWeb.Endpoint

  @interval 5_000
  @coincap_url "https://api.coincap.io/v2/assets/?limit=200"
  @coin_data_topic "coin_data"

  def start_link(initial_state) do
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  defp fetch_coin_data do
    with {:ok, %{body: body, status_code: 200}} <-
           HTTPoison.get(@coincap_url),
         {:ok, %{"data" => data}} = Jason.decode(body) do
      {:ok, data}
    else
      {:ok, %{status_code: status_code}} ->
        Logger.error("An error ouccured, status_code: #{status_code}")
        :error

      {:error, %{reason: reason}} ->
        Logger.error("An error occured, reason: #{reason}")
        :error
    end
  end

  def init(initial_state) do
    schedule_data_fetch()
    {:ok, initial_state}
  end

  def handle_info(:fetch_from_api, current_state) do
    new_state =
      case fetch_coin_data() do
        {:ok, fetched_data} ->
          Map.put(current_state, :coins_data, fetched_data)

        :error ->
          Map.put(current_state, :coins_data, nil)
      end

    schedule_data_fetch()
    Endpoint.broadcast(@coin_data_topic, "coin_data_updated", %{})
    {:noreply, new_state}
  end

  def handle_call(:get_coins_data, _from, current_state) do
    {:reply, current_state, current_state}
  end

  defp schedule_data_fetch do
    Process.send_after(self(), :fetch_from_api, @interval)
  end
end

defmodule App.CoinDataServer do
  @default_page_size 10
  def get_all_coins_data(page) do
    cleaned_data =
      GenServer.call(App.CoinDataWorker, :get_coins_data)
      |> clean_data()

    num_of_pages = number_of_pages(cleaned_data.coins_data)

    paginated = paginate(cleaned_data.coins_data, page, num_of_pages)

    %{cleaned_data | coins_data: paginated}
    |> Map.put(:pages, num_of_pages)
  end

  defp number_of_pages(coins_data_list) do
    count =
      if is_nil(coins_data_list) do
        0
      else
        length(coins_data_list)
      end

    (count / @default_page_size) |> Float.ceil() |> round()
  end

  defp paginate(list, page_number, num_of_pages) do
    start_index =
      if page_number > num_of_pages or page_number <= 0 do
        1
      else
        page_number
      end

    Enum.slice(list, (start_index - 1) * @default_page_size, @default_page_size)
  end

  defp clean_data(%{coins_data: coins_data_list} = data)
       when coins_data_list == [] or is_nil(coins_data_list) do
    data
  end

  defp clean_data(%{coins_data: coins_data_list} = data) do
    cleaned_data =
      coins_data_list
      |> Enum.map(fn coin_data_map -> trim_map_values(coin_data_map) end)

    %{data | coins_data: cleaned_data}
  end

  defp trim_map_values(coin_data_map) do
    coin_data_map
    |> Enum.map(fn {key, value} -> parse_and_shorten_value(key, value) end)
    |> Enum.into(%{})
  end

  defp parse_and_shorten_value(key, value) when is_nil(value) do
    {key, value}
  end

  defp parse_and_shorten_value(key, value)
       when key in [
              "marketCapUsd",
              "maxSupply",
              "supply",
              "volumeUsd24Hr"
            ] do
    readable_value = number_to_human(value)
    {key, readable_value}
  end

  defp parse_and_shorten_value(key, value)
       when key in ["priceUsd", "vwap24Hr", "changePercent24Hr"] do
    {
      key,
      value
      |> Number.Conversion.to_float()
      |> Float.floor(2)
      |> Float.to_string()
    }
  end

  defp parse_and_shorten_value(key, value) do
    {key, value}
  end

  defp number_to_human(nil) do
    nil
  end

  defp number_to_human(value) do
    new_value =
      value
      |> Number.Human.number_to_human()
      |> String.split(" ")

    case new_value do
      [number, prefix] ->
        number <> String.at(prefix, 0)

      _ ->
        value
    end
  end
end

defmodule App.CoinDataAPI do
  require Logger

  def get_all(options) do
    {page, per_page} = get_paginate_options(options)
    {sort_by, sort_order} = get_sort_options(options)

    data = GenServer.call(App.CoinDataServer, :get_all)

    num_of_pages = get_number_of_pages(data.data, per_page)

    sorted =
      data.data
      |> sort_data(sort_by, sort_order)
      |> paginate_data(page, num_of_pages, per_page)

    clean_data(%{data | data: sorted}) |> Map.put(:pages, num_of_pages)
  end

  def get_one(id) do
    data = GenServer.call(App.CoinDataServer, {:get_one, %{id: id}})

    case data do
      nil ->
        nil

      :error ->
        nil

      data ->
        data
        |> Enum.map(fn {key, value} -> parse_and_shorten_value(key, value) end)
        |> Enum.into(%{})
    end
  end

  def get_history(id, interval) do
    fetch_params = %{id: id, interval: interval}
    data = GenServer.call(App.CoinDataServer, {:fetch_coin_history, fetch_params}, 10000)

    data
    |> clean_history_data()
    |> create_plot_data(interval)
  end

  defp get_number_of_pages(coins_data_list, per_page) do
    count =
      if is_nil(coins_data_list) do
        0
      else
        length(coins_data_list)
      end

    (count / per_page) |> Float.ceil() |> round()
  end

  defp get_paginate_options(options) do
    %{page: page, per_page: per_page} = Keyword.get(options, :paginate)
    {page, per_page}
  end

  defp get_sort_options(options) do
    %{sort_by: sort_by, sort_order: sort_order} = Keyword.get(options, :sort)
    {sort_by, sort_order}
  end

  defp sort_data(data, sort_by, sort_order)
       when sort_by in [
              "priceUsd",
              "marketCapUsd",
              "changePercent24Hr",
              "supply",
              "volumeUsd24Hr"
            ] do
    Enum.sort_by(data, fn map -> map[sort_by] |> String.to_float() end, sort_order)
  end

  defp sort_data(data, sort_by, sort_order) when sort_by == "rank" do
    Enum.sort_by(
      data,
      fn map ->
        map[sort_by] |> String.to_integer()
      end,
      sort_order
    )
  end

  defp sort_data(data, sort_by, sort_order) when sort_by == "name" do
    Enum.sort_by(data, &Map.fetch(&1, sort_by), sort_order)
  end

  defp paginate_data(list, page_number, num_of_pages, per_page) do
    start_index =
      if page_number > num_of_pages or page_number <= 0 do
        1
      else
        page_number
      end

    Enum.slice(list, (start_index - 1) * per_page, per_page)
  end

  defp clean_data(%{data: coins_data_list} = data)
       when coins_data_list == [] or is_nil(coins_data_list) do
    data
  end

  defp clean_data(%{data: coins_data_list} = data) do
    cleaned_data =
      coins_data_list
      |> Enum.map(fn coin_data_map -> trim_map_values(coin_data_map) end)

    %{data | data: cleaned_data}
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

  defp clean_history_data(data) do
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

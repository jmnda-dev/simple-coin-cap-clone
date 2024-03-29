defmodule App.CoinDataServer do
  @moduledoc """
  A GenServer process that fetches data from the CoinCap API and
  cache.
  """
  use GenServer
  require Logger
  alias AppWeb.Endpoint

  @interval 5000
  @limit 200
  @base_url "https://api.coincap.io/v2"
  @fetch_all_url "#{@base_url}/assets/?limit=#{@limit}"
  @coin_data_topic "coin_data_update"

  def start_link(initial_state) do
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  defp fetch_data(url) do
    with {:ok, %{body: body, status_code: 200}} <-
           HTTPoison.get(url),
         {:ok, %{"data" => data}} = Jason.decode(body) do
      {:ok, data}
    else
      {:ok, %{status_code: status_code} = reason} ->
        Logger.error("An error ouccured, status_code: #{status_code}, reason: #{inspect(reason)}")
        :error

      {:error, %{reason: reason}} ->
        Logger.error("An error occured, reason: #{inspect(reason)}")
        :error
    end
  end

  def init(initial_state) do
    schedule_data_fetch()
    {:ok, initial_state}
  end

  def handle_info(:fetch_all, current_state) do
    new_state =
      case fetch_data(@fetch_all_url) do
        {:ok, fetched_data} ->
          %{current_state | data: fetched_data, loaded?: true, success?: true}

        :error ->
          %{current_state | data: [], loaded?: true, success?: false}
      end

    schedule_data_fetch()
    Endpoint.broadcast(@coin_data_topic, "data_updated", %{})
    {:noreply, new_state}
  end

  def handle_call(:get_all, _from, current_state) do
    {:reply, current_state, current_state}
  end

  def handle_call({:get_one, %{id: id}}, _from, %{data: data_list} = current_state) do
    coin_data =
      case data_list do
        :error ->
          :error

        data_list ->
          data_list
          |> Enum.find(&(&1["id"] == id))
      end

    {:reply, coin_data, current_state}
  end

  defp schedule_data_fetch do
    Process.send_after(self(), :fetch_all, @interval)
  end
end

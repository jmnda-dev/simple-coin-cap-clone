defmodule App.CoinDataWorker do
  use GenServer
  require Logger

  @interval 5_000
  @coincap_url "https://api.coincap.io/v2/assets/?limit=1"

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
        nil

      {:error, %{reason: reason}} ->
        Logger.error("An error occured, reason: #{reason}")
        nil
    end
  end

  def init(state) do
    schedule_coin_data_fetch()
    {:ok, state}
  end

  def handle_info(:fetch_from_api, state) do
    {:noreply, state}
  end

  defp schedule_coin_data_fetch do
    Process.send_after(self(), :fetch_from_api, @interval)
  end
end

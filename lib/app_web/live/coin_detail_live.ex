defmodule AppWeb.CoinDetailLive do
  use AppWeb, :live_view
  alias AppWeb.{ChartComponent, SpinnerComponent}
  alias App.CoinDataAPI
  import AppWeb.LiveHelpers
  require Logger

  def mount(_, _, socket) do
    if connected?(socket) do
      send(self(), :update)
    end

    {:ok, socket |> assign(:chart_loaded?, false)}
  end

  def render(assigns) do
    ~H"""
    <%= if is_nil(@data) do %>
      <div class="flex justify-center mt-14">
        <h1 class="md:text-5xl text-4xl">Live Crypto Currency Data</h1>
      </div>
      <div class="flex justify-center mt-5">
        <div class="spinner-container">
          <div class="spinner"></div>
        </div>
      </div>
    <% else %>
      <div class="flex flex-col items-center mt-5">
        <div class="flex">
          <div class="mask mask-squircle w-12 h-12"></div>
          <h1 class="text-4xl ml-3 mb-5"><%= @data["name"] %> (<%= @data["symbol"] %>)</h1>
        </div>
        <div class="m-5">
          <ul>
            <li class="text-xl font-semibold">Price &#11166;  $<%= @data["priceUsd"] %></li>
            <li class="text-xl font-semibold ">
              <p>
                Change Percent  &#11166;
                <span class={change_percent(@data["changePercent24Hr"])}>
                  <%= @data["changePercent24Hr"] %> %
                </span>
              </p>
            </li>
            <li class="text-xl font-semibold">
              Volume 24hr(USD)  &#11166; <%= @data["volumeUsd24Hr"] %>
            </li>
          </ul>
        </div>

        <div class="flex m-4">
          <form phx-change="interval">
            <p class="m-2 text-xl font-semibold">Interval</p>
            <select class="select select-primary w-full max-w-xs" name="interval">
              <%= options_for_select(
                [
                  "Per minute": "m1",
                  "5 minutes": "m5",
                  "15 minutes": "m15",
                  "30 minutes": "m30",
                  "Hourly ": "h1",
                  "2 hours": "h2",
                  "6 hours": "h6"
                ],
                @interval
              ) %>
            </select>
          </form>
        </div>

        <div class="flex w-full justify-center">
          <%= if not assigns.chart_loaded? do %>
            <SpinnerComponent.spinner class="w-20 h-20 mr-2 text-gray-200 animate-spin dark:text-gray-600 fill-blue-600" />
          <% else %>
            <ChartComponent.chart />
          <% end %>
        </div>
      </div>
    <% end %>
    """
  end

  def handle_params(%{"id" => coin_id} = params, _url, socket) do
    interval = params["interval"] || "h1"
    coin_data = CoinDataAPI.get_one(coin_id)
    {:noreply, socket |> assign(coin_id: coin_id, data: coin_data, interval: interval)}
  end

  def handle_info(:update, %{assigns: assigns} = socket) do
    data = CoinDataAPI.get_history(assigns.coin_id, assigns.interval)

    {:noreply,
     push_event(
       socket |> assign(chart_loaded?: true, interval: assigns.interval),
       "refresh_chart",
       data
     )}
  end

  def handle_event("interval", %{"interval" => interval}, %{assigns: assigns} = socket) do
    data = CoinDataAPI.get_history(assigns.coin_id, interval)

    {:noreply,
     push_event(
       socket |> assign(chart_loaded?: true, interval: assigns.interval),
       "refresh_chart",
       data
     )}
  end
end

defmodule AppWeb.CoinDetailLive do
  use AppWeb, :live_view
  alias AppWeb.{ChartComponent, SpinnerComponent}
  alias App.Utils.CoinDataFetcher

  def mount(_, _, socket) do
    if connected?(socket) do
      send(self(), :update)
    end

    {:ok, socket |> assign(:chart_loaded?, false)}
  end

  def render(assigns) do
    ~H"""
    <div class="text-2xl">
      Hello Coin!!
    </div>

    <div class="m-5">
      <%= if not assigns.chart_loaded? do %>
        <SpinnerComponent.spinner class="w-20 h-20 mr-2 text-gray-200 animate-spin dark:text-gray-600 fill-blue-600" />
      <% else %>
        <ChartComponent.chart />
      <% end %>
    </div>
    """
  end

  def handle_params(%{"id" => coin_id}, _url, socket) do
    {:noreply, socket |> assign(:coin_id, coin_id)}
  end

  def handle_info(:update, %{assigns: assigns} = socket) do
    data = CoinDataFetcher.get_coin_history(assigns.coin_id, "h1")
    {:noreply, push_event(socket |> assign(:chart_loaded?, true), "refresh_chart", data)}
  end
end

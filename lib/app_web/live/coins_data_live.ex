defmodule AppWeb.CoinsDataLive do
  use AppWeb, :live_view
  alias App.CoinDataServer
  alias AppWeb.{Endpoint, TableComponent}

  @coin_data_topic "coin_data"

  def mount(_, _, socket) do
    if connected?(socket) do
      Endpoint.subscribe(@coin_data_topic)
    end

    {
      :ok,
      socket
      |> assign_page_title("Live Crypto Currency Data")
      |> assign(:table_component_id, "coins-data-table")
      |> assign(:current_page, "1")
    }
  end

  def handle_params(params, _url, %{assigns: assigns} = socket) do
    page = Map.get(params, "page", "1")

    send_update(TableComponent, id: assigns.table_component_id, page: page)

    {:noreply, socket |> assign(current_page: page)}
  end

  def handle_info(%{event: "coin_data_updated"}, %{assigns: assigns} = socket) do
    send_update(TableComponent, id: assigns.table_component_id, page: assigns.current_page)

    {:noreply, socket |> assign(page: assigns.current_page)}
  end

  defp assign_page_title(socket, title) do
    assign(socket, :page_title, title)
  end
end

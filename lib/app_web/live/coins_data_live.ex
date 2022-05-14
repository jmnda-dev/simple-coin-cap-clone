defmodule AppWeb.CoinsDataLive do
  use AppWeb, :live_view
  alias AppWeb.{Endpoint, TableComponent}

  @coin_data_topic "coin_data"

  def mount(_, _, socket) do
    if connected?(socket) do
      Endpoint.subscribe(@coin_data_topic)
    end

    {:ok,
     socket
     |> assign_page_title("Live Crypto Currency Data")
     |> assign(:table_component_id, "coins-data-table")}
  end

  def assign_page_title(socket, title) do
    assign(socket, :page_title, title)
  end

  def handle_info(%{event: "coin_data_updated"}, %{assigns: assigns} = socket) do
    send_update(TableComponent, id: assigns.table_component_id)
    {:noreply, socket}
  end
end

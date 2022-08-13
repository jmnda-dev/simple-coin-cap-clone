defmodule AppWeb.CoinListingLive do
  use AppWeb, :live_view
  alias App.CoinDataAPI
  alias AppWeb.Endpoint
  import AppWeb.LiveHelpers
  import AppWeb.Components
  alias Phoenix.LiveView.JS

  @coin_data_topic "coin_data_update"

  def mount(_, _, socket) do
    if connected?(socket) do
      Endpoint.subscribe(@coin_data_topic)
    end

    {
      :ok,
      socket |> assign_page_title("Live Crypto Currency Data") |> assign(:diff_list, []),
      temporary_assigns: [diff_list: []]
    }
  end

  def handle_params(params, _url, socket) do
    page = String.to_integer(params["page"] || "1")
    per_page = String.to_integer(params["per_page"] || "40")

    sort_by = params["sort_by"] || "rank"
    sort_order = (params["sort_order"] || "asc") |> String.to_atom()

    paginate_options = %{page: page, per_page: per_page}
    sort_options = %{sort_by: sort_by, sort_order: sort_order}

    {
      :noreply,
      socket
      |> assign(paginate: paginate_options, sort: sort_options)
      |> assign(:data, assign_coins_data(paginate_options, sort_options))
    }
  end

  def handle_info(%{event: "data_updated"}, %{assigns: assigns} = socket) do
    old_data = assigns.data

    new_data =
      CoinDataAPI.get_all(
        paginate: assigns.paginate,
        sort: assigns.sort
      )

    diff = List.myers_difference(old_data.data, new_data.data)

    ins = Keyword.get(diff, :ins) || []
    diff_list = ins |> Enum.map(fn map -> map["id"] end)

    new_sock =
      socket
      |> assign(data: new_data)
      |> assign(:diff_list, diff_list)
      |> assign(
        :paginate,
        assigns.paginate
      )
      |> assign(:sort, assigns.sort)

    {
      :noreply,
      push_event(
        new_sock,
        "highlight",
        %{diff: diff_list}
      )
    }
  end

  def handle_event("select-per-page", %{"per-page" => per_page}, %{assigns: assigns} = socket) do
    paginate_options = %{assigns.paginate | per_page: String.to_integer(per_page)}

    {
      :noreply,
      socket
      |> assign(
        data: assign_coins_data(paginate_options, assigns.sort),
        paginate: paginate_options,
        sort: assigns.sort
      )
    }
  end

  def handle_event("sort", %{"sort_by" => sort_by}, %{assigns: assigns} = socket) do
    sort_options = %{
      assigns.sort
      | sort_by: sort_by,
        sort_order: toggle_sort_order(assigns.sort.sort_order)
    }

    {
      :noreply,
      socket
      |> assign(
        data: assign_coins_data(assigns.paginate, sort_options),
        paginate: assigns.paginate,
        sort: sort_options
      )
    }
  end

  defp assign_page_title(socket, title) do
    assign(socket, :page_title, title)
  end

  defp sort_link(socket, text, paginate_options, sort_by, sort_order) do
    live_patch(text,
      to:
        Routes.live_path(
          socket,
          __MODULE__,
          sort_by: sort_by,
          sort_order: toggle_sort_order(sort_order),
          page: paginate_options.page,
          per_page: paginate_options.per_page
        )
    )
  end

  defp toggle_sort_order(:asc), do: :desc
  defp toggle_sort_order(:desc), do: :asc

  defp assign_coins_data(paginate_options, sort_options) do
    CoinDataAPI.get_all(
      paginate: paginate_options,
      sort: sort_options
    )
  end

  def sort_icon(col_name, sort_by, :asc) when col_name == sort_by, do: "🔽️"
  def sort_icon(col_name, sort_by, :desc) when col_name == sort_by, do: "🔼️"
  def sort_icon(_, _, _), do: ""

  def highlight(js, id, diff_list) do
    if id in diff_list do
      JS.transition(js, {"transition ease-in-out delay-150", "bg-sky-200", "bg-white-100"},
        time: 1000
      )
    else
      JS.transition(js, {"transition ease-in-out delay-150", "bg-base", "bg-base"}, time: 1000)
    end
  end
end

defmodule AppWeb.CoinListingLive do
  use AppWeb, :live_view
  alias App.CoinDataAPI
  alias AppWeb.SpinnerComponent
  alias AppWeb.Endpoint
  import AppWeb.LiveHelpers

  @coin_data_topic "coin_data_update"

  def mount(_, _, socket) do
    if connected?(socket) do
      Endpoint.subscribe(@coin_data_topic)
    end

    {
      :ok,
      socket
      |> assign_page_title("Live Crypto Currency Data")
    }
  end

  def handle_params(params, _url, socket) do
    page = String.to_integer(params["page"] || "1")
    per_page = String.to_integer(params["per_page"] || "10")

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

  def render(assigns) do
    ~H"""
    <div class="flex justify-center mt-14">
      <h1 class="md:text-5xl text-4xl">Live Crypto Currency Data</h1>
    </div>

    <div class="flex m-4">
      <form phx-change="select-per-page">
        <p class="m-2 text-xl font-semibold">Items per page</p>
        <select class="select select-primary w-full max-w-xs" name="per-page">
          <%= options_for_select([10, 15, 20, 40], @paginate.per_page) %>
        </select>
      </form>
    </div>

    <div class="flex justify-center mt-5">
      <div class="overflow-x-auto w-full">
        <div>
          <div class="flex">
            <table class="table w-full">
              <%= if is_nil(@data.data) do %>
                <p>An error occured while retrieving data</p>
              <% end %>

              <%= if @data.data == [] do %>
                <SpinnerComponent.spinner class="w-20 h-20 mr-2 text-gray-200 animate-spin dark:text-gray-600 fill-blue-600" />
              <% end %>

              <%= if @data.data != [] and not is_nil(@data.data) do %>
                <!-- head -->
                <thead>
                  <tr>
                    <th>
                      <%= sort_link(
                        @socket,
                        "Rank " <> sort_icon("rank", @sort.sort_by, @sort.sort_order),
                        @paginate,
                        "rank",
                        @sort.sort_order
                      ) %>
                    </th>
                    <th>
                      <%= sort_link(
                        @socket,
                        "Name " <> sort_icon("name", @sort.sort_by, @sort.sort_order),
                        @paginate,
                        "name",
                        @sort.sort_order
                      ) %>
                    </th>
                    <th>
                      <%= sort_link(
                        @socket,
                        "Price " <> sort_icon("priceUsd", @sort.sort_by, @sort.sort_order),
                        @paginate,
                        "priceUsd",
                        @sort.sort_order
                      ) %>
                    </th>
                    <th>
                      <%= sort_link(
                        @socket,
                        "Market Cap " <> sort_icon("marketCapUsd", @sort.sort_by, @sort.sort_order),
                        @paginate,
                        "marketCapUsd",
                        @sort.sort_order
                      ) %>
                    </th>
                    <th>
                      VWAP
                    </th>
                    <th>
                      <%= sort_link(
                        @socket,
                        "Supply " <> sort_icon("supply", @sort.sort_by, @sort.sort_order),
                        @paginate,
                        "supply",
                        @sort.sort_order
                      ) %>
                    </th>
                    <th>
                      <%= sort_link(
                        @socket,
                        "Volume(24Hr) " <>
                          sort_icon("volumeUsd24Hr", @sort.sort_by, @sort.sort_order),
                        @paginate,
                        "volumeUsd24Hr",
                        @sort.sort_order
                      ) %>
                    </th>
                    <th>
                      <%= sort_link(
                        @socket,
                        "Change(24Hr) " <>
                          sort_icon("changePercent24Hr", @sort.sort_by, @sort.sort_order),
                        @paginate,
                        "changePercent24Hr",
                        @sort.sort_order
                      ) %>
                    </th>
                    <th></th>
                  </tr>
                </thead>
                <tbody>
                  <%= for coin_data <- @data.data do %>
                    <tr>
                      <td><%= coin_data["rank"] %></td>
                      <td>
                        <div class="flex items-center space-x-3">
                          <div class="avatar">
                            <div class="mask mask-squircle w-12 h-12">
                              <img
                                src={
                                  "https://assets.coincap.io/assets/icons/#{coin_data["symbol"] |> String.downcase()}@2x.png"
                                }
                                alt="Avatar Tailwind CSS Component"
                              />
                            </div>
                          </div>
                          <div>
                            <div class="font-bold"><%= coin_data["name"] %></div>
                            <div class="text-sm opacity-50"><%= coin_data["symbol"] %></div>
                          </div>
                        </div>
                      </td>
                      <td>
                        $ <%= coin_data["priceUsd"] %>
                      </td>
                      <td><%= coin_data["marketCapUsd"] %></td>
                      <td><%= coin_data["vwap24Hr"] %></td>
                      <td><%= coin_data["supply"] %></td>
                      <td><%= coin_data["volumeUsd24Hr"] %></td>
                      <td>
                        <span class={change_percent(coin_data["changePercent24Hr"])}>
                          <%= coin_data["changePercent24Hr"] %>
                        </span>
                      </td>
                      <th>
                        <%= live_redirect to: Routes.live_path(@socket, AppWeb.CoinDetailLive, coin_data["id"] |> String.downcase() ) do %>
                          <button class="btn btn-ghost btn-xs">details</button>
                        <% end %>
                      </th>
                    </tr>
                  <% end %>
                </tbody>
              <% end %>
            </table>
          </div>

          <div class="flex justify-center mt-3">
            <div class="btn-group">
              <%= for page <- 1..@data.pages do %>
                <%= if page == @paginate.page do %>
                  <%= live_patch to: Routes.live_path(@socket, __MODULE__, page: page, per_page: @paginate.per_page, sort_by: @sort.sort_by, sort_order: @sort.sort_order), class: "btn-disabled" do %>
                    <button class="btn btn-md btn-disabled"><%= page %></button>
                  <% end %>
                <% else %>
                  <%= live_patch to: Routes.live_path(@socket, __MODULE__, page: page, per_page: @paginate.per_page, sort_by: @sort.sort_by, sort_order: @sort.sort_order) do %>
                    <button class="btn btn-md"><%= page %></button>
                  <% end %>
                <% end %>
              <% end %>
            </div>
          </div>
        </div>
        <div class="m-5"></div>

        <div class="m-5"></div>
      </div>
    </div>
    """
  end

  def handle_info(%{event: "data_updated"}, %{assigns: assigns} = socket) do
    {
      :noreply,
      socket |> assign(data: assign_coins_data(assigns.paginate, assigns.sort))
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
end

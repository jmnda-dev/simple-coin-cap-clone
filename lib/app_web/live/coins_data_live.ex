defmodule AppWeb.CoinsDataLive do
  use AppWeb, :live_view
  alias App.CoinDataServer
  alias AppWeb.SpinnerComponent
  alias AppWeb.Endpoint

  @coin_data_topic "coin_data"

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
              <%= if is_nil(@data.coins_data) do %>
                <p>An error occured while retrieving data</p>
              <% end %>

              <%= if @data.coins_data == [] do %>
                <SpinnerComponent.spinner class="w-20 h-20 mr-2 text-gray-200 animate-spin dark:text-gray-600 fill-blue-600" />
              <% end %>

              <%= if @data.coins_data != [] and not is_nil(@data.coins_data) do %>
                <!-- head -->
                <thead>
                  <tr>
                    <th>Rank</th>
                    <th>Name</th>
                    <th>Price</th>
                    <th>Market Cap</th>
                    <th>VWAP</th>
                    <th>Supply</th>
                    <th>Volume(24Hr)</th>
                    <th>Change(24Hr)</th>
                    <th></th>
                  </tr>
                </thead>
                <tbody>
                  <%= for coin_data <- @data.coins_data do %>
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
                      <td><%= coin_data["changePercent24Hr"] %></td>
                      <th>
                        <button class="btn btn-ghost btn-xs">details</button>
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
                  <%= live_patch to: Routes.coins_data_path(@socket, :index, page: page, per_page: @paginate.per_page), class: "btn-disabled" do %>
                    <button class="btn btn-md btn-disabled"><%= page %></button>
                  <% end %>
                <% else %>
                  <%= live_patch to: Routes.coins_data_path(@socket, :index, page: page, per_page: @paginate.per_page) do %>
                    <button class="btn btn-md"><%= page %></button>
                  <% end %>
                <% end %>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def handle_info(%{event: "coin_data_updated"}, %{assigns: assigns} = socket) do
    {
      :noreply,
      socket |> assign(data: assign_coins_data(assigns.paginate, assigns.sort))
    }
  end

  defp assign_page_title(socket, title) do
    assign(socket, :page_title, title)
  end

  # def sort_link(socket, link_text, sort_by, options) do
  #   live_patch(link_text,
  #     to:
  #       Routes.live_path(socket, __MODULE__,
  #         sort_by: sort_by,
  #         sort_order: toggle_sort_order(options.sort_order)
  #       )
  #   )
  # end

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

  defp toggle_sort_order(:asc), do: :desc
  defp toggle_sort_order(:desc), do: :asc

  defp assign_coins_data(paginate_options, sort_options) do
    CoinDataServer.get_all_coins_data(
      paginate: paginate_options,
      sort: sort_options
    )
  end
end

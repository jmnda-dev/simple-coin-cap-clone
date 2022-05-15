defmodule AppWeb.TableComponent do
  use AppWeb, :live_component
  alias App.CoinDataServer
  alias AppWeb.SpinnerComponent

  def update(assigns, socket) do
    page = Map.get(assigns, :page, "1")

    {
      :ok,
      socket
      |> assign(:data, assigns_coins_data(page))
      |> assign(:current_page, page)
    }
  end

  def render(assigns) do
    ~H"""
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
                -
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
            <%= if page == String.to_integer(@current_page) do %>
              <%= live_patch to: Routes.coins_data_path(@socket, :index, page: page), class: "btn-disabled" do %>
                <button class="btn btn-md btn-disabled"><%= page %></button>
              <% end %>
            <% else %>
              <%= live_patch to: Routes.coins_data_path(@socket, :index, page: page) do %>
                <button class="btn btn-md"><%= page %></button>
              <% end %>
            <% end %>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp assigns_coins_data(page) do
    CoinDataServer.get_all_coins_data(page)
  end
end

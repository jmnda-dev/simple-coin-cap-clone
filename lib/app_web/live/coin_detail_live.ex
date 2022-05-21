defmodule AppWeb.CoinDetailLive do
  use AppWeb, :live_view

  def mount(socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="text-2xl">
      Hello Coin!!
    </div>
    """
  end
end

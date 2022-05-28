defmodule AppWeb.ChartComponent do
  use Phoenix.Component
  use Phoenix.HTML

  def chart(assigns) do
    ~H"""
    <div class="md:w-4/5 w-full">
      <canvas phx-hook="Chart" id="myChart"></canvas>
    </div>
    """
  end
end

defmodule AppWeb.ChartComponent do
  use Phoenix.Component
  use Phoenix.HTML

  def chart(assigns) do
    ~H"""
    <p>hello</p>

    <canvas phx-hook="Chart" id="myChart"></canvas>
    """
  end
end

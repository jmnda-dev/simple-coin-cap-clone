defmodule AppWeb.LiveHelpers do
  def change_percent(change) do
    number = String.to_float(change)

    css_color =
      if number > 0 do
        "text-green-600"
      else
        "text-red-600"
      end

    css_color
  end
end

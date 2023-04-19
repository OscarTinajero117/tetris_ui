defmodule TetrisUiWeb.TetrisLive do
  use Phoenix.LiveView
  alias Tetris.Brick

  def mount(_params, _session, socket) do
    {
      :ok,
      assign(
        socket, 
        tetromino: Brick.new_random |> Brick.to_string,
      )
    }
  end

  def render(assigns) do
    ~H"""
    <pre><%= @tetromino %></pre>
    """
  end
end
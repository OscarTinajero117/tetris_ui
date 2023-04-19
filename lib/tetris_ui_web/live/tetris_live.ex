defmodule TetrisUiWeb.TetrisLive do
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    {
      :ok,
      assign(socket, hello: "Hello", name: "Oscar")
    }
  end

  def render(assigns) do
    ~H"""
    <h1><%= @hello %></h1>
    <h2><%= @name %></h2>
    """
  end
end
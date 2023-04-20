defmodule TetrisUiWeb.TetrisLive do
  use Phoenix.LiveView

  import Phoenix.HTML, only: [raw: 1]

  alias Tetris.Brick
  alias Tetris.Points

  @box_width 20
  @box_height 20

  def mount(_params, _session, socket) do
    {:ok, new_game(socket)}
  end

  def render(assigns) do
    ~H"""
    <div phx-window-keydown="keydown">
      <%= raw(svg_head()) %>
      <%= raw(boxes(@tetromino)) %>
      <%= raw(svg_foot()) %>
    </div>
    """
  end

  defp new_game(socket) do
    assign(socket,
      state: :playing,
      score: 0,
      bottom: %{}
    )
    |> new_block
    |> show
  end

  def new_block(socket) do
    brick =
      Brick.new_random()
      |> Map.put(:location, {3, -3})

    assign(socket, brick: brick)
  end

  def show(socket) do
    brick = socket.assigns.brick

    points =
      brick
      |> Brick.prepare()
      |> Points.move_to_location(brick.location)
      |> Points.with_color(Brick.color(brick))

    assign(socket, tetromino: points)
  end

  def svg_head() do
    """
      <svg
      version="1.0"
      style="background-color: #F4F4F4;"
      id="Layer_1"
      xmlns="http://www.w3.org/2000/svg"
      xmlns:xlink="http://www.w3.org/1999/xlink"
      width="200" height="400"
      viewBox="0 0 200 400"
      xml:space= "preserve" >
    """
  end

  def svg_foot(), do: "</svg>"

  def boxes(brick) do
    brick
    |> Enum.map(fn {x, y, color} -> box({x, y}, color) end)
    |> Enum.join("\n")
  end

  def box(point, color) do
    """
      #{square(point, shades(color).light)}
      #{triangle(point, shades(color).dark)}
    """
  end

  def square(point, shade) do
    {x, y} = to_pixels(point)

    """
    <rect
        x="#{x + 1}" y="#{y + 1}"
        style="fill: ##{shade};"
        width="#{@box_width - 2}" height="#{@box_height - 1}" />
    """
  end

  def triangle(point, shade) do
    {x, y} = to_pixels(point)
    {w, h} = {@box_width, @box_height}

    """
    <polyline
        style="fill: ##{shade};"
        points="#{x + 1},#{y + 1} #{x + w},#{y + 1} #{x + w},#{y + h}" />
    """
  end

  defp to_pixels({x, y}), do: {(x - 1) * @box_width, (y - 1) * @box_height}

  defp shades(:red), do: %{light: "DB7160", dark: "AB574B"}
  defp shades(:blue), do: %{light: "83C1C8", dark: "66969C"}
  defp shades(:green), do: %{light: "8BBF57", dark: "769359"}
  defp shades(:orange), do: %{light: "CB8E4E", dark: "AC7842"}
  defp shades(:grey), do: %{light: "A1A09E", dark: "7F7F7E"}

  def drop(socket) do
    socket
    |> do_drop
    |> show
  end

  def move(direction, socket) do
    socket
    |> do_move(direction)
    |> show
  end

  def do_drop(%{assigns: assigns} = socket) do
    brick = assigns.brick |> Brick.down()

    assign(socket, brick: brick)
  end

  def do_move(%{assigns: assigns} = socket, :right) do
    brick = assigns.brick |> Tetris.try_right(assigns.bottom)

    assign(socket, brick: brick)
  end

  def do_move(%{assigns: assigns} = socket, :left) do
    brick = assigns.brick |> Tetris.try_left(assigns.bottom)

    assign(socket, brick: brick)
  end

  def do_move(%{assigns: assigns} = socket, :turn) do
    brick = assigns.brick |> Tetris.try_spin_90(assigns.bottom)

    assign(socket, brick: brick)
  end

  def handle_event("keydown", %{"key" => "ArrowLeft"}, socket) do
    {:noreply, move(:left, socket)}
  end

  def handle_event("keydown", %{"key" => "ArrowRight"}, socket) do
    {:noreply, move(:right, socket)}
  end

  def handle_event("keydown", %{"key" => "z"}, socket) do
    {:noreply, move(:turn, socket)}
  end

  def handle_event("keydown", %{"key" => "ArrowDown"}, socket) do
    {:noreply, drop(socket)}
  end

  def handle_event("keydown", _, socket), do: {:noreply, socket}
end

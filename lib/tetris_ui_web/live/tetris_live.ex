defmodule TetrisUiWeb.TetrisLive do
  use Phoenix.LiveView
  use PetalComponents

  import Phoenix.HTML, only: [raw: 1]

  alias Tetris.Brick
  alias Tetris.Points

  @box_width 40
  @box_height 40

  def mount(_params, _session, socket) do
    :timer.send_interval(400, self(), :tick)

    {:ok, start_game(socket)}
  end

  def render(%{state: :starting} = assigns) do
    ~H"""
    <.container max_width="full" class="content-center bg-[url('https://wallpapercave.com/wp/wp2675365.jpg')]">
      <.container max_width="lg" class="mt-10 mb-10 border-2 bg-white">
        <.h1 class="text-center mt-5">Tetris</.h1>
        <.p class="text-center mt-5">Press the button to start the game!!!</.p>
        <.container class="flex flex-wrap items-end justify-center my-1 rounded-md">
          <.button icon={:play} size="lg" phx-click="start" color="primary" label="Start" class="mb-10" />
        </.container>
        <.h2 class="text-center mt-5">Instructions</.h2>
        <.p class="text-center mt-5">Use the arrow keys to move the blocks left and right and down. Press the "z" to rotate the block.</.p>
        <.container class="h-56 grid grid-cols-3 gap-4 content-center">
          <div></div>
          <.h2>z</.h2>
          <div></div>
          <.icon name={:arrow_left} class="h-10 text-gray-700 dark:text-gray-300"/>
          <.icon name={:arrow_down} class="h-10 text-gray-700 dark:text-gray-300"/>
          <.icon name={:arrow_right} class="h-10 text-gray-700 dark:text-gray-300"/>
        </.container>
      </.container>
    </.container>
    """
  end

  def render(%{state: :playing} = assigns) do
    ~H"""
    <.container max_width="full" class="content-center bg-[url('https://wallpapercave.com/wp/wp2675365.jpg')]">
      <.container max_width="lg" class="mt-10 mb-10 border-2 bg-white">
        <.h1 class="text-center mt-5">Tetris</.h1>
        <.h2 class="text-left mt-5 pl-8">Score: <%= @score %></.h2>
        <.container phx-window-keydown="keydown" class="flex flex-wrap items-end justify-center my-3 py-5 rounded-md">
          <%= raw(svg_head()) %>
          <%= raw(boxes(@tetromino)) %>
          <%= raw(boxes(Map.values(@bottom))) %>
          <%= raw(svg_foot()) %>
        </.container>
      </.container>
    </.container>
    """
  end

  def render(%{state: :game_over} = assigns) do
    ~H"""
    <.container max_width="full" class="content-center bg-[url('https://wallpapercave.com/wp/wp2675365.jpg')]">
      <.container max_width="lg" class="mt-10 mb-10 border-2 bg-white">
        <.h1 class="text-center mt-5">Game Over</.h1>
        <.h3 class="text-center mt-5">Your Score: <%= @score %></.h3>
        <.container class="flex flex-wrap items-end justify-center my-1 rounded-md">
          <.button icon={:arrow_path} size="lg" phx-click="start" color="primary" label="Play again?" class="mb-10" />
        </.container>
      </.container>
    </.container>
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

  defp start_game(socket) do
    assign(socket,
      state: :starting
    )
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
      width="400" height="800"
      viewBox="0 0 400 800"
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
    old_brick = socket.assigns.brick

    response =
      Tetris.drop(
        old_brick,
        socket.assigns.bottom,
        Brick.color(old_brick)
      )

    socket
    |> assign(
      brick: response.brick,
      bottom: response.bottom,
      score: response.score + socket.assigns.score,
      state: if(response.game_over, do: :game_over, else: :playing)
    )
    |> show
  end

  def drop(:playing, socket) do
    old_brick = socket.assigns.brick

    response =
      Tetris.drop(
        old_brick,
        socket.assigns.bottom,
        Brick.color(old_brick)
      )

    socket
    |> assign(
      brick: response.brick,
      bottom: response.bottom,
      score: response.score + socket.assigns.score,
      state: if(response.game_over, do: :game_over, else: :playing)
    )
    |> show
  end

  def drop(_nothing_, socket) do
    socket
    |> new_block
    |> show
  end

  def move(direction, socket) do
    socket
    |> do_move(direction)
    |> show
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

  def handle_event("keydown", _, socket) do
    {:noreply, socket}
  end

  def handle_event("start", _, socket) do
    {:noreply, new_game(socket)}
  end

  def handle_info(:tick, socket) do
    {:noreply, drop(socket.assigns.state, socket)}
  end
end

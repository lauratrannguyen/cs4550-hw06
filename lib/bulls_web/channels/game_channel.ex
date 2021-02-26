# Channel connected to the socket.js
defmodule BullsWeb.GameChannel do
  use BullsWeb, :channel
  alias Bulls.Server
  alias BullsWeb.Game

  # Puts users all together
  defp user(view, user) do
    Map.put(view, :userName, user);
  end

  # Prints out the error message to the screen
  defp error(view, err) do 
    Map.put(view, :error, err);
  end


  # Handles all the users in the newView
  @impl true
  def handle_info({:after_join, gameName}, socket) do
    newView = Server.view(gameName);
    # BroadCast
    broadcast(socket, "view", newView);
    {:noreply, socket};
  end

  # Puts the error in the broadcast
  intercept ["view"]
  @impl true
  def handle_out("view", msg, socket) do
    push(socket, "view", error(user(msg, socket.assigns[:userName]), socket.assigns[:error]));
    # BroadCast
    {:noreply, socket}
  end

  defp authorized?(_payload) do
    true
  end

  @impl true
  def handle_info("onClose", socket) do
    {:noreply, socket};
  end 

  # Handles the user joining the gameroom
  @impl true
  def join("gameroom:" <> gameName, %{"userName" => userName} = payload, socket) do
    if(gameName == "" || userName == "") do
      view = Game.end_view();
      {:ok, view, socket};
    else 
      if authorized?(payload) do
        # Creates the game room
        Server.newGame(gameName);
        # Joins the user to the new game room
        Server.user(gameName, userName)
        # Returns the view to the user
        view = Server.view(gameName);
        # Shows the user to other users
        send(self(), {:after_join, gameName});
        soc = assign(socket, :userName, userName)
        |> assign(:gameName, gameName);
        {:ok, user(view, userName), soc};
      else
        {:error, %{reason: "unauthorized"}}
      end
    end
  end

  # Handles the user leaving a game and observing
  @impl true
  def handle_in("leave game", _payload, socket) do
    user = socket.assigns[:userName];
    game = socket.assigns[:gameName];
    # User leaves
    Server.leave(game, user);
    # Begins the round
    Server.round_begin(game);
    Server.check_attempt(game);
    send(self(), {:after_join, game});
    # Clears the socket for the room
    soc = assign(socket, :gameName, nil)
    |> assign(:userName, nil)
    view = Game.end_view();
    {:reply, {:ok, view}, socket};
  end

  # Switches user to observer and not if wanted
  @impl true
  def handle_in("observer", _payload, socket) do
    user = socket.assigns[:userName];
    game = socket.assigns[:gameName];
    # Makes user an observer
    Server.observer(game, user);
    # Begins the round
    Server.round_begin(game);
    # BroadCast
    send(self(), {:after_join, game});
    {:noreply, socket};
  end

  # Switches user to ready
  @impl true
  def handle_in("ready", _payload, socket) do
    user = socket.assigns[:userName];
    game = socket.assigns[:gameName];
    # Toggle observer
    Server.ready(game, user);
    # Check Ready
    Server.round_begin(game);
    # BroadCast
    send(self(), {:after_join, game});
    {:noreply, socket};
  end

  # Evaluates the user's guess
  @impl 
  def handle_in("guess", %{"guess" => guess} = payload, socket) do
    game = socket.assigns[:gameName];
    user = socket.assigns[:userName];
    {_status, msg} = Server.guess(game, user, guess);
    soc = assign(socket, :error, msg);
    Server.check_attempt(game);
    # BroadCast
    send(self(), {:after_join, game});
    {:noreply, soc};
  end

  # Allows the user to pass
  @impl
  def handle_in("pass", _payload, socket) do
    game = socket.assigns[:gameName];
    user = socket.assigns[:userName];
    Server.pass(game, user);
    Server.check_attempt(game);
    # BroadCast
    send(self(), {:after_join, game});
    {:noreply, socket};
  end
end
# Actions of the server
defmodule Bulls.Server do
    alias BullsWeb.Game

    # State 
    @impl true
    def init(state) do 
        {:ok, state}
    end 

    # Starts the game
    def handle_cast({:start, gameName}, state) do
        case Game.start_bulls(state) do
            {:error, old} ->
                {:noreply, old};
            {:ok, new} ->
                Process.send_after(self(), {:check_out, gameName, 0}, 30000);
                {:noreply, new};
        end
    end

    # Joins the game
    def handle_cast({:join, userName}, state) do
        {:noreply, Game.join_bulls(state, userName)};
    end

    # Updates the view
    def handle_call(:view, _from, state) do
        {:reply, Game.view(state), state};
    end

    # For the observer
    def handle_cast({:observer, userName}, state) do
        case Game.observe_bulls(state, userName) do 
            {:ok, new} -> {:noreply, new};
            {:error, msg} -> {:noreply, state};
        end 
    end

    # Readys the player
    def handle_cast({:ready, userName}, state) do
        case Game.ready_bulls(state, userName) do
            {:ok, new} -> {:noreply, new};
            {:error, msg} -> {:noreply, state};
        end
    end

    # Leaves the game
    def handle_cast({:leave, userName}, state) do
        case Game.leave_bulls(state, userName) do
            {:ok, new} -> {:noreply, Game.try_reset(new)};
            {:error, _msg} -> {:noreply, state}
        end
    end

    # Hangles the user's guess
    def handle_call({:guess, userName, guess}, _from, state) do
        case Game.guess_bulls(state, userName, guess) do
            {:error, err} -> {:reply, {:error, err}, state};
            {:ok, msg, new} -> {:reply, {:ok, msg}, new};
        end
    end

    # Pass in the game
    def handle_cast({:pass, userName}, state) do
        case Game.pass_bulls(state, userName) do
            {:error, _msg} -> 
                {:noreply, state}
            {:ok, new} -> 
                {:noreply, new};
        end
    end

    # Checks the attempt
    def handle_cast({:try_check}, state) do
        case Game.end_round(state) do
            {:ok, eval} ->
                Process.send_after(self(), {:check_out, eval.gameName, eval.turn}, 30000);
                {:noreply, eval};
            {:error, uneval} ->
                {:noreply, uneval};
        end 
    end

    # Evaluates the turn
    def handle_info({:check_out, gameName, turn}, state) do
        if(state.turn == turn && state.game) do
            new = Game.is_it_over(state);
            if (new.game) do
                Process.send_after(self(), {:check_out, gameName, new.turn}, 30000);
            end
            BullsWeb.Endpoint.broadcast("game:" <> gameName, "view", Game.view(new));
            {:noreply, new};
        else 
            {:noreply, state};
        end 
    end

    def reg(gameName) do
        {:via, Registry, {Bulls.Registry, gameName}}
    end

    # With the game room, starts a new game
    def newGame(gameName) do
        spec = %{
            id: __MODULE__,
            start: {__MODULE__, :start_link, [gameName]},
            restart: :permanent,
            type: :worker,
        }
        if(Registry.lookup(Bulls.Registry, gameName)) do
            Bulls.Sup.start_child(spec);
        else
            {:ok}
        end
    end

    def start_link(gameName) do
        game = Game.new(gameName);
        GenServer.start_link(__MODULE__, game, name: reg(gameName))
    end

    def view(gameName) do
        GenServer.call(reg(gameName), :view);
    end

    def user(gameName, userName) do
        GenServer.cast(reg(gameName), {:join, userName});
    end

    def leave(gameName, userName) do
        GenServer.cast(reg(gameName), {:leave, userName});
    end

    def observer(gameName, username) do
        GenServer.cast(reg(gameName), {:observer, username});
    end

    def ready(gameName, username) do
        GenServer.cast(reg(gameName), {:ready, username});
    end

    def guess(gameName, username, guess) do
        GenServer.call(reg(gameName), {:guess, username, guess});
    end

    def round_begin(gameName) do
        GenServer.cast(reg(gameName), {:start, gameName});
    end

    def pass(gameName, userName) do
        GenServer.cast(reg(gameName), {:pass, userName});
    end

    def check_attempt(gameName) do
        GenServer.cast(reg(gameName), {:try_check});
    end 
end
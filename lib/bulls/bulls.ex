# Server side functions from App.js
defmodule BullsWeb.Game do

    #Creates a new game state
    def new(gameName) do
        %{
            # Game Room that user picks
            gameName: gameName,
            # Whether game is over or not
            game: false,
            # Tally of wins and losses for users
            leaderBoard: %{}, 
            # Users in the game
            users: %{}, 
            # Observers watching the ongoing game
            observers: MapSet.new(),
            # The winner of the previous game
            lastWin: [],
            # State of the game (based on App.js)
            # Outcomes of the user guesses
            outcomes: [], 
            # Outcomes of the current round based on user's guesses
            tempResults: [], 
            # The current tally for a player
            currTally: [], 
            # Generates the random secret code
            secret: secret("", ["1", "2", "3", "4", "5", "6", "7", "8", "9"]),
            # User's that have already guesses
            guessed: [],
            # What number round of the game currently on
            round: 0
        }
    end
    
    # Creates the secret code
    defp secret(build, nums) do
        if String.length(build) < 4 do
            rand = Enum.random(nums);
            if(String.length(build) == 0) do
                secret(build <> rand, nums -- [rand] ++ [0]);
            else 
                secret(build <> rand, nums -- [rand]);
            end 
        else 
            build
        end
    end 

    # Current View of the game
    def view(state) do
        %{
            gameName: state.gameName,
            game: state.game,
            observers: MapSet.to_list(state.observers),
            users: state.users,
            lastWin: state.lastWin,
            leaderBoard: state.leaderBoard,
            outcomes: state.outcomes
        }
    end

    # when view is over 
    def end_view() do 
        %{
            gameName: "",
            userName: "",
            observers: [],
            users: [],
            outcomes: [],
            preWinner: [],
            leaderBoard: []
        }
    end 

    # Updates the list of users and observers every time a new user joins the game room
    def join_bulls(state, user) do
        if(MapSet.member?(state.observers, user) || Map.has_key?(state.users, user)) do
            # returns current state
            state;
        else 
           newUser =  MapSet.put(state.observers, user);
           %{state | observers: newUser};
        end
    end

    # Updates the list of users and observers every time a user becomes an observer
    def observe_bulls(state, user) do
        #If game hasn't started ...
        if !state.game do
            cond do
                Map.has_key?(state.users, user) ->
                    newPlayers = Map.delete(state.users, user);
                    newUser = MapSet.put(state.observers, user);
                    newState = %{state | observers: newUser};
                    {:ok, %{newState | users: newPlayers}};
                MapSet.member?(state.observers, user) ->
                    newUser = MapSet.delete(state.observers, user);
                    newPlay = Map.put(state.users, user, false);
                    newState = %{state | observers: newUser};
                    {:ok, %{newState | users: newPlay}};
                true ->  {:error, error: "Unknown User"};
            end
        else 
            {:error, error: "Game has started"};
        end
    end

    # Readys the user if they click the ready button
    def ready_bulls(state, user) do
        if(!state.game) do
            cond do
                Map.has_key?(state.users, user) -> 
                    newPlay = Map.update!(state.users, user, fn(rdy) -> !rdy end);
                    {:ok, %{state | users: newPlay}};
                MapSet.member?(state.observers, user) -> 
                    {:error, "Not a User"};
                true ->  {:error, error: "Unknown User"};     
            end
        else 
            {:error, "Game has started"};
        end
    end

    # Updates the list of users and observers every time a user leaves the game room
    def leave_bulls(state, user) do
        cond do
            Map.has_key?(state.users, user) ->
                newPlay = Map.delete(state.users, user);
                {:ok, %{state | users: newPlay}};
            MapSet.member?(state.observers, user) -> 
                newUser = MapSet.delete(state.observers, user);
                {:ok, %{state | observers: newUser}};
            true -> {:error, "Unknown User"}
        end
    end

    # If there's 4 players, start the bulls game
    def start_bulls(state) do
        if (Enum.all?(state.users, fn {_username, status} -> status end) && map_size(state.users) == 4) do
            newState = %{state | 
            game: true,
            lastWin: []};
            {:ok, newState}
        else 
            {:error, state}
        end
    end

    # Checks whether a user is an observer. If they are, don't let them play
    def guess_bulls(state, user, guess) do
        if(MapSet.member?(state.observers, user)) do
            {:error, "An observer"};
        else
            if !Enum.member?(state.guessed, user) do
                {out, msg} = valid(state, guess)
                case valid(state, guess) do
                    {:ok, msg} ->
                        {status, computed} = result(state.secret, guess, 0, 0, 0);
                        {:ok, msg, %{state | guessed: state.guessed ++ [user], 
                            tempResults: state.tempResults ++ [[user, guess, {status, computed}]]
                        }}
                    {:error, msg} -> {:error, msg}
                end
            else
                {:ok, "User already guesses", state}
            end
        end
    end
    
    # Updates the winner to the leaderboard
    defp updateWin(state, winner) do
        cond do
            # If there is no winner, clear the users that have already guesses
            length(state.tempResults) == 0 && winner == 0 ->
                %{state |
                    guessed: []
                }
            # If there is a winner, the game is over and state returns back to normal
            length(state.tempResults) == 0 && winner > 0 ->
                %{state |
                    game: false,
                    guessed: []
                }
            # Continue the game
            true ->
                first = hd(state.tempResults)
                {status, result} = Enum.at(first, 2)
                user = Enum.at(first, 0);
                guess = Enum.at(first, 1);
                # If user has won, make them the last winner and update the currTally
                if status != 1 do
                    state = %{state |
                        outcomes: state.outcomes ++ [[user, guess, result]],
                        # Evaluates the rest of the results
                        tempResults: tl(state.tempResults),
                        currTally: state.currTally ++ [[user, status]]
                    }
                    updateWin(state, winner)
                else 
                    state = %{state |
                        outcomes: state.outcomes ++ [[user, guess, result]],
                        tempResults: tl(state.tempResults),
                        currTally: state.currTally ++ [[user, status]],
                        lastWin: state.lastWin ++ [user]
                    }
                    updateWin(state, winner+1)
                end
        end
    end

    # Updates the leaderboard
    defp newBoard(state) do
        # Returns the original state since no games have been played
        if length(state.currTally) == 0 do
            # Return the original state
            state    
        else 
            first = hd(state.currTally)
            user = Enum.at(first, 0)
            winner = Enum.at(first, 1)

            if Map.has_key?(state.leaderBoard, user) do
                newState = %{ state |
                    currTally: tl(state.currTally),
                    # Updates the leaderboard with wins and losses
                    leaderBoard: Map.update!(state.leaderBoard, user, fn(prev) ->
                        [Enum.at(prev, 0) + winner, Enum.at(prev, 1) + (1-winner)] 
                    end)
                }
                newBoard(newState)
            else
                newLeaderBoard = Map.put(state.leaderBoard, user, [winner, 1-winner])
                newState = %{state |
                    currTally: tl(state.currTally),
                    leaderBoard: newLeaderBoard
                }
                newBoard(newState)
            end
        end
    end

    # Restarts the game for the next round
    defp restart(state) do
        newS = newBoard(state)
        newState = %{ newS |
            # Generates a new secret
            secret: secret("", ["1", "2", "3", "4", "5", "6", "7", "8", "9"]),
            outcomes: [],
            round: 0,
            game: false
        }
        newPlay = Enum.map(newState.users, fn{userName, status} -> {userName, !status} end)
        |> Enum.into(%{})
        %{ newState | users: newPlay }
    end

    # Is the guess a number
    defp valid_num(str) do
        try do
            _j = String.to_integer(str);
            true;
        rescue
            ArgumentError -> false;
        end 
    end 

    # Has the guess already been chosen?
    defp guess_exists(outcomes, guess) do
        if length(outcomes) == 0 do
            false
        else 
            first = hd(outcomes)
            if Enum.at(first, 1) == guess do
                true
            else
                false or guess_exists(tl(outcomes), guess)
            end 
        end
    end

    # Is the guess valid
    defp valid(state, guess) do
        userGuess = MapSet.new(String.split(guess, "", trim: true));
        cond do 
            String.at(guess, 0) == "0" -> 
                {:error, "Please input a guess with no 0s"}
            MapSet.size(userGuess) != 4 || String.length(guess) != 4 -> 
                {:error, "Please input 4 digits"}
            !valid_num(guess) -> 
                {:error, "Please input only numbers"}
            guess_exists(state.outcomes, guess) ->
                {:error, "Guess was already guessed"};
            true -> 
                {:ok, "Guess Inputted"}
        end 
    end 

    # Computes the Guess
    defp result(secret, guess, i, b, c) do
        if(i < String.length(guess)) do
            cond do
            String.at(guess, i) == String.at(secret, i) ->
                result(secret, guess, i + 1, b + 1, c);
            String.contains?(secret, String.at(guess, i)) ->
                result(secret, guess, i + 1, b, c + 1);
            true ->
                result(secret, guess, i + 1, b, c);
            end 
        else 
            if(b == 4) do
                {1, "#{b}B#{c}C"}
            else 
                {0, "#{b}B#{c}C"}
            end 
        end 
    end 

    # If there is a pass, skip that user
    def user_pass(state, users) do
        if length(users) == 0 do
            state
        else 
            first = hd(users)
            if Enum.member?(state.guessed, first) do
                user_pass(state, tl(users))
            else
                newState = %{ state |
                    tempResults: state.tempResults ++ [[first, "pass", {0, "0B0C"}]]
                }
                user_pass(newState, tl(users))
            end
        end
    end

    # Lets a user pass the game
    def pass_bulls(state, user) do
        if(MapSet.member?(state.observers, user)) do
            {:error, "An observer"};
        else
            if !Enum.member?(state.guessed, user) do
                {:ok, %{state | 
                guessed: state.guessed ++ [user],
                tempResults: state.tempResults ++ [[user, "pass", {0, "0B0C"}]]
                }};
            else
                {:error, state}
            end
        end
    end

    # Try reset
    def try_reset(state) do
        if(map_size(state.users) == 0) do
            restart(state);
        else 
            state;
        end 
    end 

    # Ends round once all users have made a guess
    def end_round(state) do
        if length(state.guessed) == map_size(state.users) && state.game do
             {:ok, is_it_over(state)} 
         else
             {:error, state}
         end 
     end

    # If game is over, return to game room
    def is_it_over(state) do
        newS = user_pass(state, Map.keys(state.users))
        newState = updateWin(newS, 0)
        if !newState.game do
            restart(newState);
        else 
            %{newState |
                currTally: [],
                round: newState.round + 1
            }
        end
    end
end 
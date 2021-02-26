import "phoenix_html";

import React, { useState, useEffect } from 'react';
import { ch_gameroom, ch_join, update, ch_leave_game, ch_observer, ch_ready, ch_guess, ch_pass} from './socket';

import Gameroom from './gameroom';
import Bulls from './bulls';

import ReactDOM from 'react-dom';

// Builds the multiplayer bulls game
function App() {
    const [state, setState] = useState({
        outcomes: [],
        lastWin: [],
        leaderBoard: [],
        users: [],
        observers: [],
        gameName: "",
        userName: "",
        error: "",
    })

    // Updates the state with every new userinput
    useEffect(() => {
        update(state);
        ch_join(setState);
    })

    // Updates the gamename the user inputs
    const newGamename = (ev) => {
        setState((prev) => ({
            ...prev,
            gameName: ev.target.value
        }))
    }

    // Updates the username the user inputes
    const newUsername = (ev) => {
        setState((prev) => ({
            ...prev,
            userName: ev.target.value
        }))
    }

    // Joins the game with the button
    function joinGame() {
        ch_gameroom(state.gameName, state.userName);
    }

    // Changes user to oberserver or not
    function observer() {
        ch_observer();
    }

    // Ready's user for game
    function ready() {
        ch_ready();
    }

    // Allows user to leave the game
    function leave() {
        ch_leave_game();
    }

    // Takes in the user's new guess
    function newGuess(guess) {
        ch_guess(guess);
    }

    // lets the user pass
    function pass() {
        ch_pass();
    }

    // Creates the opening screen the user first sees
    if (typeof (state.game) == "undefined") {
        return (
            <div>
            <center><h1>Bulls and Cows</h1>
            <div>Instructions:</div>
            <div>Guess the secret 4 digit combo.</div>
            <div>Once a guess has been made, it will be evaluated in the results column.</div>
            <div>B means you have a right digit in the right place.</div>
            <div>C means you have a right digit in the wrong place.</div>
            <div>You have 8 attempts</div>
            <div>Good Luck!</div></center>
            <p></p>
            <h2>Enter a game room and the name other people will see:</h2>
            <h3>Game Name</h3>
            <input onChange={newGamename} value={state.gameName} type="text" />
            <h3>Username</h3>
            <input onChange={newUsername} value={state.userName} type="text" />
            <button onClick={joinGame}>Join</button>
            </div>
            )
    }

    // Returns the lobby based on the user's input
    else if (!state.game){
        return (
            <Gameroom
                users={state.users}
                userName={state.userName}
                gamename={state.gameName}
                leaderBoard={state.leaderBoard}
                previous={state.lastWin}
                ready={ready}
                observer={observer}
                observers={state.observers}
                leave={leave}
            />
        )
    }
    // Returns the screen where a game is taking place
    else {
        return (
            <Bulls
                leave={leave}
                guess={newGuess}
                pass={pass}
                outcomes = {state.outcomes} 
                error = {state.error}
            />
        )
    }
}

// Renders the app
ReactDOM.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
  document.getElementById('root')
);


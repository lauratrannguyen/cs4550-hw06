import React, { useState } from 'react';

// Returns the game screen
function Bulls(props) {
  const [state, setState] = useState("");
  // error message for an invalid guess
  let error;
  // List of outcomes based on user guesses
  let outcomes = [];

  // Changes the user 
  const changeUser = (ev) => {
    setState(ev.target.value);
  }

  // Tkaes in the user's guess
  function userGuess() {
    setState("");
    props.newGuess(state);
  }

  // If there's an error, update the error
  if (props.error) {
    error = props.error;
  }
  else {
    error = "";
  }

  // Creates the results table
  for (let i = 0; i < props.outcomes.length; i++) {
    if (props.outcomes[i][1] !== "pass") {
      outcomes.push(
        <tr>
          <td>{props.outcomes[i][0]}</td>
          <td>{props.outcomes[i][1]}</td>
          <td>{props.outcomes[i][2]}</td>
        </tr>
      )
    }
  }

  // How the bulls and cows game looks like
  return (
    <div>
      <h1>Bulls and Cows Game</h1>
      <h3>Enter a unique, 4 digit guess: </h3>
      <input type="text" maxLength="4" onChange={changeUser} value={state}  />
      <h2>{error}</h2>
      <div><button onClick={userGuess}>Guess</button></div>
      <div><button onClick={props.pass}>Pass</button></div>
      <div><button onClick={props.leave}>Leave Game</button></div>
      <table>
        <thead>
          <tr>
            <td>Username</td>
            <td>Guess</td>
            <td>Outcome</td>
          </tr>
        </thead>
        <tbody>
          {outcomes}
        </tbody>
      </table>
    </div>);
}

export default Bulls;
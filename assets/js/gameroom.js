import React from 'react';

// Creates the second screen for the lobby with the users
function Gameroom(props) {
    let users = [];
    let observerList = [];
    let previous = "";
    let leaders = [];
    
    // Creates the player list of users in the game
    for (const [key, value] of Object.entries(props.users)) {
        users.push(
            <tr>
                <td>{key}</td>
                <td>{"" + value}</td>
            </tr>
        )
    }
    // Creates the list of observers
    for(let i = 0; i < props.observers.length; i++) {
        observerList.push(
            <tr>
                <td>{`Observer Name: ${props.observers[i]}`}</td>
            </tr>
        )
    }

    // Established the previous winner
    console.log(props.previous);
    if(props.previous) {
        previous = props.previous.toString();
    } 

    // Creates the leaders and win/loss summary
    let i = 0;
    for (const [i, [key, value]] of Object.entries(Object.entries(props.leaderBoard))) {
        leaders.push(
            <tr>
                <td>{key}</td>
                <td>{`Wins: ${value[0]}, Losses: ${value[1]}`}</td>
            </tr>
        )
    }
    // Returns the lobby screen
    return (
        <div><center>
            <h1>Game Name: {props.gamename}</h1>
            <h1>Username: {props.userName}</h1>
            <div><button onClick={props.observer}>Become an Observer</button></div>
            <div><button onClick={props.ready}>Ready</button></div>
            <div><button onClick={props.leave}>Leave Room</button></div>
            <h3>Observers</h3>
            <table>
                <tbody>
                    {observerList}
                </tbody>
            </table>
            <h3>Players</h3>
            <table>
                <thead>
                    <tr>
                        <th>User</th>
                        <th>Ready?</th>
                    </tr>
                </thead>
                <tbody>
                    {users}
                </tbody>
            </table>
            <h3>Last Winner's Name: {previous}</h3>
            <h3>Leaderboard</h3>
            <table>
                <thead>
                    <tr>
                        <th>User</th>
                        <th>Wins and Loss Summary</th>
                    </tr>
                </thead>
                <tbody>
                    {leaders}
                </tbody>
            </table>
        </center></div>
    )

}

export default Gameroom;
import { Socket } from "phoenix"

let socket = new Socket("/socket", { params: { token: "" } })

socket.connect();

socket.onClose(() =>{
  channel.push("onClose", "");
});

let callback = null;
let channel = null;
let state = {
};

// updates the state
export function update(s) {
  state = s;
  console.log(s);
  if (callback) {
    callback(s);
  }
}

// Joins the new state
export function ch_join(cb) {
  callback = cb;
  callback(state);
}

// Joins the gameroom the user inputs
export function ch_gameroom(game, user) {
  channel = socket.channel("gameroom:" + game, {userName: user})
  channel.join()
    .receive("ok", response => {
      update(response);
      channel.on("view", update);
    })
    .receive("error", resp => { 
      console.log("Unable to join", resp) 
    })
}

// Changes user to observer and vice versa
export function ch_observer() {
  channel.push("observer", "");
}

// Leaves the game
export function ch_leave_game() {
  channel.push("leave game", "")
    .receive("ok", response => {
      update(response);
      channel.leave();
    })
    .receive("error", resp => { 
      console.log("Unable to reset", resp) 
    })
}

// Decides if user is ready
export function ch_ready() {
  channel.push("ready", "");
} 

// Takes in the user's guess
export function ch_guess(guess = "wrong") {
  channel.push("guess", {guess: guess});
}

// Allows user to pass
export function ch_pass() {
  channel.push("pass", "");
}

export default socket
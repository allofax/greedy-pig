'use strict';
 
// Selecting Elements
const player0El = document.querySelector('.player--0');
const player1El = document.querySelector('.player--1');
const score0El = document.querySelector('#score--0');
const score1El = document.getElementById('score--1');
const current0El = document.getElementById('current--0');
const current1El = document.getElementById('current--1');
 
const diceEl = document.querySelector('.dice');
// const btnNew = document.querySelector('.btn--new');
const btnRoll = document.querySelector('.btn--roll');
const btnHold = document.querySelector('.btn--hold');
 
// Starting conditions
let scores, currentScore, activePlayer, waitingPlayer, playing;
 
window.onload = (event) => {
  const userId = sessionStorage.id
  let action_link = "##TP_CGI_URL##?action=KOJOLU_findRoomJSON&roomId=" + ##TP_roomIdPlayer## + "&userId=" + userId;
  fetch(action_link)
  .then(data => data.text())
  .then(result => {console.log(result) 
    let gameId = JSON.parse(result).room
    sessionStorage.setItem("gameId", gameId)
  })

};

const init = function () {
  playing = true;
  currentScore = 0;
  activePlayer = 0;
  waitingPlayer = 1;
  scores = [0, 0];
 
  current0El.textContent = 0;
  current1El.textContent = 0;
  score0El.textContent = 0;
  score1El.textContent = 0;
 
  player0El.classList.add('player--active');
  player1El.classList.remove('player--active');
  player0El.classList.remove('player--winner');
  player1El.classList.remove('player--winner');
  diceEl.classList.add('hidden');
};
init();
const switchPlayer = function () {
  document.getElementById(`current--${activePlayer}`).textContent = 0;
  activePlayer = activePlayer === 0 ? 1 : 0;
  waitingPlayer = (activePlayer ? 0 : 1);
  currentScore = 0;
  player0El.classList.toggle('player--active');
  player1El.classList.toggle('player--active');
};
 
// Rolling dice functionality
 
btnRoll.addEventListener('click', function () {
    let current_user_id = sessionStorage.id
  if (playing) {
    // 1. Generating a random dice roll
    const dice = Math.trunc(Math.random() * 6) + 1;
    console.log("the dice is " + dice);
    // 2. add event to the database for the current game
    // note - 7 params: current_player_id, waiting_player_id, current_play_accum
    // roll_result, player_1_score, player_2_score, player_action (and game_id which is hardcoded)
    
	 // also - testing on predetermined figures
	 if (dice !== 1) {
      // Add dice to current score
      currentScore += dice;
      document.getElementById(`current--${activePlayer}`).textContent = currentScore;
    }
	 console.log("========pre fetch");
    var action_link = "##TP_CGI_URL##?action=KOJOLU_roll_dice_event&current_player_id=1&waiting_player_id=2&current_player_accum=" + currentScore + "&roll_result=" + dice + "&player_1_score=" + scores[0] + "&player_2_score=" +scores[1] + "&game_id=1";
    console.log("the action link is " + action_link);    
    fetch(action_link);
    console.log("========post fetch");
    
    
    // 3. Display dice
    diceEl.classList.remove('hidden');
    diceEl.src = `https://github.com/allofax/greedy-pig/blob/main/induction/training/admin/html/training/greedy_pig/dice-${dice}.png?raw=true`;
    // 4. Check for rolled 1: if true, switch to next player
    if (dice == 1) {
    	// add some code here to change to the other player
      // Switch to the next player
      switchPlayer();
    }
  }
});
 
btnHold.addEventListener('click', function () {
    let current_user_id = sessionStorage.id
  if (playing) {
    // add hold_event command to backend before doing everything else   
    console.log("INSIDE HOLD FUNCTION");
      let action_link = "##TP_CGI_URL##?action=KOJOLU_hold_event&user_id=" + current_user_id + "&current_player_accum=" + currentScore + "&player_1_score=" + scores[0] + "&player_2_score=" +scores[1] + "&game_id=26";
    fetch(action_link);
    
    // 1. Add current score to active player's
    scores[activePlayer] += currentScore;
    document.getElementById(`score--${activePlayer}`).textContent =
      scores[activePlayer];
    // 2. Check if players score is >= 100
    if (scores[activePlayer] >= 100) {
      playing = false;
      diceEl.classList.add('hidden');
      document
        .querySelector(`.player--${activePlayer}`)
        .classList.add('player--winner');
      document
        .querySelector(`.player--${activePlayer}`)
        .classList.remove('player--active');
      // 3. Switch player
    } else switchPlayer();
  }
});

// loading spinner, waiting for player to join
// if sessionStorage.id is == to res.player_1_id or player_2_id, clear interval for polling and if player 1 set spinner element to hide
// possibly have to return player usernames in JSON too to populate opponents username
function query_room_full()
{
  let action_link = `##TP_CGI_URL##?action=KOJOLU_PollPlayerTwo&gameId=${sessionStorage.gameId}`
  let action_first_event = `##TP_CGI_URL##?action=KOJOLU_insertFirst&gameId=${sessionStorage.gameId}`
  let spinner = document.getElementById("spinner")

  fetch(action_link)
  .then(response => response.text())
  .then(data => {
      console.log(data)

      let res = JSON.parse(data)
      let room_full = res.full

      console.log(res)

      if (room_full == 1)
      {
        fetch(action_first_event)
          .then(response => response.text())
          .then(data => {

          console.log(data)
          let res_2 = JSON.parse(data)
          
          console.log(res_2)

          sessionStorage.setItem("player_1_id", res_2.current_player_id)
          sessionStorage.setItem("player_2_id", res_2.waiting_player_id)
          sessionStorage.setItem("player_1_username", res_2.player_1_username)
          sessionStorage.setItem("player_2_username", res_2.player_2_username)        
          
          document.getElementById("name--0").innerHTML = `${sessionStorage.player_1_username}`
          document.getElementById("name--1").innerHTML = `${sessionStorage.player_2_username}`
        })

        clearInterval(query_room_full_interval)
        spinner.style.display = "none"
      }

    })
}

let query_room_full_interval = setInterval(query_room_full, 500)

// when action is performed on your side, update elements using js (if current_player_id is sessionStorage.id and roll)
// when action is performed by other user that is not a hold or 1, update so current_player_id is != sessionStorage.id, populate player 2 score using JSON data
// when action is performed by other user and last event is hold or 1 switch turns to your side and update other players accum/score on your screen
// on the player who held or rolled 1 (now current player id for the last event) on their end (current_player_id = sessionStorage.id), grey out button rolls and update their elements using JS
// also if the JSON returned has win then display win/loss modal
function query_last_event()
{
  let action_link = "##TP_CGI_URL##?action=KOJOLU_SOMETHING##"

  fetch(action_link)
  .then(response => response.text())
  .then(data => {

    let res = JSON.parse(data)

    // if res.roll_result is 1 or res.player_action is HOLD, set active to player 0 if sessionStorage.id is player 1 id else set active to player 1 if sessionStorage.id is player 2
    // if roll res is 1, reset accum to 0 both locally if player 1 and 



  })
}

// btnNew.addEventListener('click', init);
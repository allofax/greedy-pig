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
    
    // 2. add event to the database for the current game (game_id is hardcoded for now)    
    // if the player rolls a 1, add their score to the 
     if (dice !== 1) {
      // Add dice to current score
      currentScore += dice;
      document.getElementById(`current--${activePlayer}`).textContent = currentScore;
    var action_link = "##TP_CGI_URL##?action=KOJOLU_roll_dice_event&current_player_id=" + activePlayer + "&waiting_player_id=" + waitingPlayer + "&current_player_accum=" + currentScore + "&roll_result=" + dice + "&player_1_score=" + scores[0] + "&player_2_score=" +scores[1] + "&game_id=26";
    fetch(action_link);
    }
    
 
    
    // 3. Display dice
    diceEl.classList.remove('hidden');
    diceEl.src = `https://github.com/allofax/greedy-pig/blob/main/induction/training/admin/html/training/greedy_pig/dice-${dice}.png?raw=true`;
 
     if (dice == 1) {
        console.log("INSIDE DICE IS 1 ====")
        currentScore = 0;
       let action_link = "##TP_CGI_URL##?action=KOJOLU_roll_one_event&user_id=" + current_user_id + "&current_player_accum=" + currentScore + "&roll_result=" + dice + "&player_1_score=" + scores[0] + "&player_2_score=" +scores[1] + "&game_id=26";
      fetch(action_link);
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
 
// btnNew.addEventListener('click', init);
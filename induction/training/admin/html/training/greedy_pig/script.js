'use strict';
 
// Selecting Elements
const player0El = document.querySelector('.player--0');
const player1El = document.querySelector('.player--1');
const score0El = document.querySelector('#score--0');
const score1El = document.getElementById('score--1');
const current0El = document.getElementById('current--0');
const current1El = document.getElementById('current--1');
const name0El = document.getElementById('name--0');
const name1El = document.getElementById('name--1');
const win_modal = document.getElementById('win-modal')
const loss_modal = document.getElementById('loss-modal')
const diceEl = document.querySelector('.dice');
const btnRoll = document.querySelector('.btn--roll');
const btnHold = document.querySelector('.btn--hold');
const btnLeave = document.querySelector('.btn--leave');
 
// Starting conditions
let scores, currentScore, activePlayer, playing, userId, game_id, res, last_event_id;
window.onload = async (event) => {

  userId = sessionStorage.id
  let action_link = "##TP_CGI_URL##?action=KOJOLU_findRoomJSON&roomId=" + ##TP_roomIdPlayer## + "&userId=" + userId;
  await fetch(action_link)
  .then(data => data.text())
  .then(result => {
    let gameId = JSON.parse(result).room
    sessionStorage.setItem("gameId", gameId)

  })

  let action_link_ = `##TP_CGI_URL##?action=KOJOLU_insertFirst&gameId=${sessionStorage.gameId}`
  await fetch(action_link_)
  .then(response => response.text())
  .then(data => { 

    let results = JSON.parse(data)

    sessionStorage.setItem("game_table_player_1_id", results.game_table_player_1_id)
    sessionStorage.setItem("player_1_id", results.current_player_id)   
    sessionStorage.setItem("player_2_id", results.waiting_player_id)   
    sessionStorage.setItem("player_1_username", results.player_1_username)
    sessionStorage.setItem("player_2_username", results.player_2_username)    

  })

  let action_link_last = `##TP_CGI_URL##?action=KOJOLU_getLatestEventJSON&gameId=${sessionStorage.gameId}`
  await fetch(action_link_last)
  .then(data => data.text())
  .then(result => {
    res = JSON.parse(result)
    last_event_id = res.event_id
  })

init();

}; 

const init = function () {

  //TODO  fix this to be only true if its under 100 (game has not finished)
  if (parseInt(res.player_1_score) >= 100)
  {
    playing = false
    player0El.classList.add('player--winner')
    btnRoll.disabled = true
    btnRoll.style.background = "#ccc"
    btnHold.disabled = true
    btnHold.style.background = "#ccc"
  }
  else if (parseInt(res.player_2_score) >= 100) {
    playing = false
    player1El.classList.add('player--winner')
    btnRoll.disabled = true
    btnRoll.style.background = "#ccc"
    btnHold.disabled = true
    btnHold.style.background = "#ccc"
  }
  else
  {
    playing = true;
    player0El.classList.remove('player--winner');
    player1El.classList.remove('player--winner');
  }

  currentScore = parseInt(res.current_player_accum);
  scores = [parseInt(res.player_1_score), parseInt(res.player_2_score)];
  game_id = sessionStorage.gameId
  
  name0El.textContent = sessionStorage.player_1_username
  name1El.textContent = sessionStorage.player_2_username

  btnRoll.disabled = true
  btnRoll.style.background = "#ccc"
  btnHold.disabled = true
  btnHold.style.background = "#ccc"

  score0El.textContent = res.player_1_score;
  score1El.textContent = res.player_2_score;

  console.log(res.current_player_id)
  console.log(sessionStorage.game_table_player_1_id)

  if (parseInt(res.current_player_id) === parseInt(sessionStorage.game_table_player_1_id)) {
    
    activePlayer = 0;
    player0El.classList.add('player--active');
    player1El.classList.remove('player--active');
    current0El.textContent = res.current_player_accum;
    current1El.textContent = 0;

  } else {

    activePlayer = 1;
    player1El.classList.add('player--active');
    player0El.classList.remove('player--active');
    current0El.textContent = 0;
    current1El.textContent = res.current_player_accum;

  }

  if (parseInt(res.current_player_id) === parseInt(sessionStorage.id)) {
    btnRoll.disabled = false
    btnRoll.style.background = "white"
    btnHold.disabled = false
    btnHold.style.background = "white"
  }
  

  if (parseInt(res.roll_result) > 0) {
    diceEl.classList.remove('hidden');
    diceEl.src = `http://dev02.openbet/user_static/kpietrzy/office_static//images/dice-${res.roll_result}.png`;

  } else {
    diceEl.classList.add('hidden');
  }
};

const switchPlayer = function () {
  document.getElementById(`current--${activePlayer}`).textContent = 0;
  activePlayer = activePlayer === 0 ? 1 : 0;
  currentScore = 0;

  player0El.classList.toggle('player--active');
  player1El.classList.toggle('player--active');

};
 
// Rolling dice functionality

btnLeave.addEventListener('click', function () {
  let action_link = "##TP_CGI_URL##?action=KOJOLU_lobby";
  fetch(action_link);
});

 
btnRoll.addEventListener('click', function () {

  if (playing) {
    const dice = Math.trunc(Math.random() * 6) + 1;

	 if (dice !== 1) {
      currentScore += dice;
      document.getElementById(`current--${activePlayer}`).textContent = currentScore;
      let action_link = "##TP_CGI_URL##?action=KOJOLU_roll_dice_event&current_player_id=" + userId + "&roll_result=" + dice + "&game_id=" + game_id;
      fetch(action_link);    
    }

    diceEl.classList.remove('hidden');
    diceEl.src = `http://dev02.openbet/user_static/kpietrzy/office_static//images/dice-${dice}.png`;
    
    if (dice == 1) {
    let action_link = "##TP_CGI_URL##?action=KOJOLU_roll_one_event&user_id=" + userId + "&game_id=" + game_id;
    fetch(action_link); 
    switchPlayer();
    }
  }
});
 
btnHold.addEventListener('click', function () {
  if (playing) {
    // add hold_event command to backend before doing everything else   
    let action_link = "##TP_CGI_URL##?action=KOJOLU_hold_event&user_id=" + userId + "&game_id=" + game_id;
    fetch(action_link);
    
    // 1. Add current score to active player's
    scores[activePlayer] += currentScore;
    document.getElementById(`score--${activePlayer}`).textContent = 
      scores[activePlayer];
    // 2. Check if players score is >= 100
    if (scores[activePlayer] >= 100) {
      
      let action_link = "##TP_CGI_URL##?action=KOJOLU_win_event&user_id=" + userId + "&game_id=" + game_id;
      fetch(action_link);
      
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

function check_modal()
{
  if (parseInt(res.player_1_score) >= 100 || parseInt(res.player_2_score) >= 100)
  {
    if (parseInt(sessionStorage.id) == parseInt(res.waiting_player_id))
    {
        win_modal.style.display = "block"
    }
    else
    {
        loss_modal.style.display = "block"
    }
    clearInterval(query_latest_event)
  }
  
}

function go_lobby(event) {
  event.preventDefault();

  document.getElementById("hidden_username").value = sessionStorage.username;
  document.getElementById("hidden_id").value = sessionStorage.id;
  console.log(
    document.getElementById("hidden_username").value,
    document.getElementById("hidden_id").value
  );
  document.getElementById("loss-modal").submit();
}

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

      let res = JSON.parse(data)
      let room_full = res.full


      if (room_full == 1)
      {
        fetch(action_first_event)
          .then(response => response.text())
          .then(data => {

          let res_2 = JSON.parse(data)

          sessionStorage.setItem("game_table_player_1_id", res_2.game_table_player_1_id)
          sessionStorage.setItem("player_1_id", res_2.current_player_id)
          sessionStorage.setItem("player_2_id", res_2.waiting_player_id)
          sessionStorage.setItem("player_1_username", res_2.player_1_username)
          sessionStorage.setItem("player_2_username", res_2.player_2_username)    
        
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
async function query_last_event()
{
  
  let action_link_last = `##TP_CGI_URL##?action=KOJOLU_getLatestEventJSON&gameId=${sessionStorage.gameId}`

  await fetch(action_link_last)
  .then(data => data.text())
  .then(result => {
    res = JSON.parse(result)
  })
  
  check_modal()
  
  if (parseInt(last_event_id) !== parseInt(res.event_id)) {
      init()
  }

}

let query_latest_event = setInterval(query_last_event, 250)


// btnNew.addEventListener('click', init);
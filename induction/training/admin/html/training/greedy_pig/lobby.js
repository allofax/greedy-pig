'use strict';

<<<<<<< HEAD

// Get the button that opens the modal
var btn = document.getElementById("funds-btn");
var okay_btn = document.getElementById("modal-close-btn");

let btnDeposit = document.getElementById("deposit-btn");
let inputDeposit = document.getElementById("amount-input");
=======
// Get the modal
var modal = document.getElementById("fund-modal");
const gameModal = document.getElementById("game-modal")
// Get the button that opens the modal
var btn = document.getElementById("funds-btn");
var span = document.getElementById("modal-close-btn");
const btnDeposit = document.getElementById("deposit-btn");
const inputDeposit = document.getElementById("amount-input");
const btnLobby = document.getElementById("join-btn")
let userid = document.getElementById("userId")
>>>>>>> 4756c8e (ADDING lucas Roll Dice, and Changes to joining a game)

// When the user clicks on the button, open the modal
btn.onclick = function () {
<<<<<<< HEAD

  var action_link = "##TP_CGI_URL##?action=KOJOLU_checklimit&id=" + sessionStorage.id;

  fetch(action_link)
  .then(response => response.text())
  .then(data => {
    
      console.log(data)
      console.log(JSON.parse(data))
      var res = JSON.parse(data)
      var is_reached = res["is_reached"]
      sessionStorage.setItem("remaining_limit", res["remaining_limit"])
      
      if  (is_reached == 1) {
        var modal = document.getElementById("error-modal");        
        okay_btn.addEventListener("click", function () {modal.style.display = "none";})
      }
      else {
        var modal = document.getElementById("fund-modal");        
      }

      modal.style.display = "block";
      
      // When the user clicks anywhere outside of the modal, close it
      window.onclick = function (event) {
        if (event.target == modal) {
          modal.style.display = "none";
        }
      };
        
  }) 
=======
  modal.style.display = "block";
};
// When the user clicks on <span> (x), close the modal
span.onclick = function () {
  modal.style.display = "none";
};
// When the user clicks anywhere outside of the modal, close it
window.onclick = function (event) {
  if (event.target == modal) {
    modal.style.display = "none";
  } else if (event.target == gameModal) {
      gameModal.style.display = "none";
  }
>>>>>>> 4756c8e (ADDING lucas Roll Dice, and Changes to joining a game)
};
// Check if user Balance is greater than stake
function checkBalance (event, balance, roomStake) {

<<<<<<< HEAD
// btnDeposit.onclick = function() {
//   let username = 'Xavier'
//   let amount = inputDeposit.value
//   console.log(amount)
//   let action_link = "##TP_CGI_URL##?action=KOJOLU_deposit&username=" + username + "&amount=" + amount;
//   console.log(action_link)
  
//   fetch(action_link)
// }
function box_col ()
{
  console.log(inputDeposit.value)

  if (inputDeposit.value <= 0 || inputDeposit.value > 100 || inputDeposit.value > sessionStorage.remaining_limit)
  {
    inputDeposit.style.background = "#db6767"  
    
  } 
  else
  {
      inputDeposit.style.background = "white"  

  }
=======
  if (balance < roomStake) {
    event.preventDefault();
    gameModal.style.display = "block";
  } 
>>>>>>> 4756c8e (ADDING lucas Roll Dice, and Changes to joining a game)
}

async function test () {
  console.log(inputDeposit.value)
  
  if (inputDeposit.value <= 0 || inputDeposit.value > 100 || inputDeposit.value > sessionStorage.remaining_limit)
  {
    inputDeposit.style.background = "#db6767"  
    return
  }

  inputDeposit.style.background = "white"  

  // let userid = sessionStorage.id
  // console.log("USER ID ======="+userid);
  // let amount = inputDeposit.value
  // console.log(amount)
  // let action_link = "##TP_CGI_URL##?action=KOJOLU_deposit&userid=" + userid + "&amount=" + amount;
  
  // await fetch(action_link)
  // location.reload();

}


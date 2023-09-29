'use strict';

// Get the modal
var modal = document.getElementById("fund-modal");
var modal_content = document.getElementById("fund-modal-content")
var gameModal = document.getElementById("game-modal")
// Get the button that opens the modal
var btn = document.getElementById("funds-btn");
var okay_btn = document.getElementById("modal-close-btn");
const btnDeposit = document.getElementById("deposit-btn");
const inputDeposit = document.getElementById("amount-input");
const btnLobby = document.getElementById("join-btn")
let userid = document.getElementById("userId")
var error_text = document.getElementById("invalid-funds")

// When the user clicks on the button, open the modal
btn.onclick = function () {

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
      
  }) 
};

window.onclick = function (event) {
  if (event.target == gameModal) {
    gameModal.style.display = "none";
  } 
  else if (event.target == modal) {
    modal.style.display = "none";
  }
}

function box_col(event) {

  var inputValue = parseFloat(event.target.value);

  if (!isNaN(inputValue)) {
      if (inputValue <= 0 || inputValue > 100 || inputValue > sessionStorage.remaining_limit) {
          event.target.style.background = "#db6767";

          if (inputValue <= 0) {
            error_text.innerHTML = "Cannot deposit zero or negative values"          
            error_text.style.display = "block"
            modal_content.style.height = "20rem"            
          }
          else if (inputValue > sessionStorage.remaining_limit) {
            error_text.innerHTML = "You cannot deposit more than your remaining allowance"          
            error_text.style.display = "block"
            modal_content.style.height = "22rem"            
          }
          else if (inputValue > 100) {
            error_text.innerHTML = "Cannot deposit more than £100.00 a day"          
            error_text.style.display = "block"  
            modal_content.style.height = "18rem"                      
          }

      } else {
          event.target.style.background = "white";
          error_text.innerHTML = ""          
          error_text.style.display = "none"
          modal_content.style.height = "18rem"                   
      }
  } else {
      // Handling non-numeric input
      event.target.style.background = "white";
      error_text.innerHTML = ""          
      error_text.style.display = "none"    
  }
}


// Check if user Balance is greater than stake
function checkBalance (event, balance, roomStake) {

  if (balance < roomStake) {
    event.preventDefault();
    gameModal.style.display = "block";
  } 
}

async function test () {

  var inputValue = parseFloat(inputDeposit.value);

  if (inputValue <= 0 || inputValue > 100 || inputValue > sessionStorage.remaining_limit)
  {
    return;
  }

  let userid = sessionStorage.id
  console.log("USER ID ======="+userid);
  let amount = inputDeposit.value
  console.log(amount)
  let action_link = "##TP_CGI_URL##?action=KOJOLU_deposit&userid=" + userid + "&amount=" + amount;
  
  await fetch(action_link)
  location.reload();

}


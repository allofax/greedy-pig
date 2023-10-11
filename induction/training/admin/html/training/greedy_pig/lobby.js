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
const forms = document.querySelectorAll('form');
let count = 0;
// When the user clicks on the button, open the modal

window.onload = (event) => {
  Array.from(forms).forEach((form) => {
    if (count !== 0) {

    if (parseInt(form.balance.value) < parseInt(form.roomStake.value) && form.session_text.value == "/") {

        form.join_btn.disabled = true
        form.join_btn.style.background = "#ccc"
    }
  } 
  count ++
  });

}


inputDeposit.addEventListener("input", validationHandler)
inputDeposit.addEventListener("blur", validationHandler)

function validationHandler (e) {
    if (e.target.value === "" || parseInt(e.target.value) > parseInt(sessionStorage.remaining_limit)) {
    
        error_text.innerHTML = "Please enter a valid amount"
        error_text.style.display = "block"
        inputDeposit.style.background = "#db6767";
        btnDeposit.classList.add("button--invisible");
        btnDeposit.disabled = true

    } else {
        error_text.innerHTML = ""
        error_text.style.display = ""
        inputDeposit.style.background = "";
        btnDeposit.classList.remove("button--invisible");
        btnDeposit.disabled = false

    }
}

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

        sessionStorage.setItem("next_top_up_time", res["next_top_up_time"])
        var modal = document.getElementById("error-modal");
        var modal_time = document.getElementById("error-modal-text-time") 

        modal_time.innerHTML = `You will be able to deposit again at ${sessionStorage.next_top_up_time}`        
        okay_btn.addEventListener("click", function () {modal.style.display = "none";})
      }
      else {
        if (res.refresh == undefined){
           var modal = document.getElementById("fund-modal"); 
        }
        else {
          location.reload()
        }

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
            modal_content.style.height = "20rem"                      
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
async function checkBalance (event, roomId, userId, balance, roomStake) {   
  event.preventDefault();
  let action_link = "##TP_CGI_URL##?action=KOJOLU_findRoomJSON&roomId=" + roomId + "&userId=" + userId;
  let gameId = ""

  await fetch(action_link)
  .then(data => data.text())
  .then(result => {console.log(result) 
    gameId = JSON.parse(result).room

  })

  if ((parseInt(gameId) == 0) && balance < roomStake) {
    gameModal.style.display = "block";
  } else {
    document.getElementById(`game-box${roomId}`).submit()
  }
}

async function deposit () {

  var inputValue = parseFloat(inputDeposit.value);

  if (inputValue <= 0 || inputValue > 100 || inputValue > sessionStorage.remaining_limit)
  {
    return;
  }

  let userid = sessionStorage.id
  console.log("USER ID ======="+userid);
  let amount = inputDeposit.value
  console.log(amount)
  let action_link = "##TP_CGI_URL##?action=KOJOLU_deposit&userid=" + userid + "&amount=" + amount + "&transactionType=DEPOSIT";
  
  await fetch(action_link)
  location.reload();

}


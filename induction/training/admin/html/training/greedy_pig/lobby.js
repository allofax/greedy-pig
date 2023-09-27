'use strict';

// Get the modal
var modal = document.getElementById("fund-modal");
// Get the button that opens the modal
var btn = document.getElementById("funds-btn");
var span = document.getElementById("modal-close-btn");
let btnDeposit = document.getElementById("deposit-btn");
let inputDeposit = document.getElementById("amount-input");


// When the user clicks on the button, open the modal
btn.onclick = function () {
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
  }
};

// btnDeposit.onclick = function() {
//   let username = 'Xavier'
//   let amount = inputDeposit.value
//   console.log(amount)
//   let action_link = "##TP_CGI_URL##?action=KOJOLU_deposit&username=" + username + "&amount=" + amount;
//   console.log(action_link)
  
//   fetch(action_link)
// }

function test () {
  let username = 'Xavier'
  let amount = inputDeposit.value
  console.log(amount)
  let action_link = "##TP_CGI_URL##?action=KOJOLU_deposit&username=" + username + "&amount=" + amount;
  console.log(action_link)
  
  fetch(action_link)
}
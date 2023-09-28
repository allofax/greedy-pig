'use strict';


// Get the button that opens the modal
var btn = document.getElementById("funds-btn");
var okay_btn = document.getElementById("modal-close-btn");

let btnDeposit = document.getElementById("deposit-btn");
let inputDeposit = document.getElementById("amount-input");

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
      
      // When the user clicks anywhere outside of the modal, close it
      window.onclick = function (event) {
        if (event.target == modal) {
          modal.style.display = "none";
        }
      };
        
  }) 
};

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
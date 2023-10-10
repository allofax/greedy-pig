'use strict';

// Function to color-code the "RESULT" column
function colorCodeResults() {
  var resultCells = document.querySelectorAll('td:nth-child(3)'); // Select all third-column cells

  resultCells.forEach(function(cell) {
    
    var result = cell.textContent.trim(); // Get the text content of the cell

    if (result === 'WIN') {
      cell.style.color = '#39ef91'; // Change text color to green for "WIN"
    } else if (result === 'LOSS') {
      cell.style.color = '#db5656'; // Change text color to red for "LOSS"
    }
    
  });
}

// Add an event listener to execute the function when the page loads
window.addEventListener('load', colorCodeResults);


function go_lobby(event) {
  event.preventDefault();

  document.getElementById("hidden_username").value = sessionStorage.username;
  document.getElementById("hidden_id").value = sessionStorage.id;
  document.getElementById("back").submit();
}
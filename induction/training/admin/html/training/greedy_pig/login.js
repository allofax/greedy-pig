'use strict';

let userid = document.getElementById('userid')
const usernameEl = document.getElementById('username-input')
const loginbtn = document.getElementById("login-btn")
const username_element = document.querySelector("input[name='username']")
const error_text = document.getElementById("invalid-username")


window.onload = (event) => {
    sessionStorage.clear()
} 
usernameEl.addEventListener("input", validationHandler)
usernameEl.addEventListener("blur", validationHandler)

function validationHandler (e) {
    if (e.target.value === "" || e.target.value.length > 30) {
    
        error_text.innerHTML = "Please enter a valid username"
        error_text.style.display = "block"
        username_element.style.background = "#db6767";
        loginbtn.classList.add("button--invisible");
        loginbtn.disabled = true

    } else {
        error_text.innerHTML = ""
        error_text.style.display = ""
        username_element.style.background = "";
        loginbtn.classList.remove("button--invisible");
        loginbtn.disabled = false

    }
}
function send_details(event)
{
    let username = document.querySelector("input[name='username']").value.trim();

    var action_link = "##TP_CGI_URL##?action=KOJOLU_login&username=" + username;

     fetch(action_link)
        .then(response => response.text())
        .then(data => {
            console.log(data)
            console.log(JSON.parse(data))
            var res = JSON.parse(data)
            sessionStorage.setItem("id",res["id"])
            sessionStorage.setItem("username",res["username"])    
            userid.value += res["id"]
            document.getElementById("login-box").submit()
        }) 
}
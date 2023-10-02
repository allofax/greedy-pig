'use strict';

let userid = document.getElementById('userid')

function send_details(event)
{
    event.preventDefault()
    
    let username_element = document.querySelector("input[name='username']")
    let username = document.querySelector("input[name='username']").value.trim();
    let error_text = document.getElementById("invalid-username")

    if (username === "")
    {
        error_text.style.display = "block"
        username_element.style.background = "#db6767";
        return
    }


    console.log(username)
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

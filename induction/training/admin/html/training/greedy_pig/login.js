'use strict';

let userid = document.getElementById('userid')

function send_details(event)
{
    event.preventDefault()

    var username = document.querySelector("input[name='username']").value.trim();
    console.log(username)
    var action_link = "http://dev02.openbet/kpietrzy.admin?action=KOJOLU_login_JSON&username=" + username;

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

'use strict';


function send_details()
{
    username = document.querySelector("input[name='username_id']").value.trim();
    console.log(username)
    action_link = "##TP_CGI_URL##?action=KOJOLU_login&username=" + username;
    fetch(action_link)
}

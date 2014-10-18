/* onsearch event handler and search event types on html5 input[type="search"] 
   by @girlie_mac

   The search event is triggered when a user:
    1. submits the search input 
    2. clears the search field (= clicks the x)

*/

var s = document.getElementById("search"),

s.addEventListener("search", function(e) {
    var q = s.value;
    
    if(q == "") {
        tw.style.display = "none";
    } else {
        tw.style.display = "block";
    }

    alert(q);
    // showTweets(q);
    
}, false);
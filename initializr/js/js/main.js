function cow(){
    $.get(
	    "http://localhost:8080/search?s=foo",
	    {s : 'foo'},
	    function(data) {
	       alert('page content: ' + data);
	    }
	);
}
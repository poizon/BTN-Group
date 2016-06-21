function init_ajax(){
    if (window.XMLHttpRequest) {
        try {
            return new XMLHttpRequest();
        } catch (e){}
    } else if (window.ActiveXObject) {
        try {
            return new ActiveXObject('Msxml2.XMLHTTP');
        } catch (e){
          try {
              return new ActiveXObject('Microsoft.XMLHTTP');
          } catch (e){}
        }
    }
    return null;
}

function loadDoc(link, id){
  req=init_ajax();

  if (req){
     req.onreadystatechange = function () {
        // Статус 4 означает успешное выполнение
        if (req.readyState == 4) {

          if (req.status == 200) {
             var response = req.responseText;
             document.getElementById(id).innerHTML = response;
          } else {
            alert('Невозможно получить данные с сервера: ' + req.statusText);
          }
        }
     }

     if(/\?/.test(link))
      link = link  + '&' + Math.random();
     else
      link = link  + '?' + Math.random();


     req.open("GET", link, true);
     req.send(null);
  }
}

function loadDocAsync(link){

  //req=init_ajax();
  var req;
  if (window.XMLHttpRequest){
     req = new XMLHttpRequest();
  } else if (window.ActiveXObject) {
     // Если нет, то работаем с ИЕ, где все не как у людей
     req = new ActiveXObject("Microsoft.XMLHTTP");
  }
	
	if (req){
		req.onreadystatechange = function () {
        // Статус 4 означает успешное выполнение
        if (req.readyState == 4) {

          if (req.status != 200) {
            alert('Невозможно получить данные с сервера: ' + req.statusText);
          }
        }
     }

     if(/\?/.test(link))
      link = link  + '&' + Math.random();
     else
      link = link  + '?' + Math.random();

     req.open("GET", link, false);
     
     req.send(null);
		 return req.responseText;

  }
}

function out_capture(opt){	
	var capture=loadDocAsync('/get_capture.pl?action=out_key&'+opt);
	document.write(capture);
}

function out_capture1(opt){
     //setTimeout(function(){
	//var capture=
	document.getElementById('out_capture1').innerHTML = loadDocAsync('/get_capture.pl?action=out_key&'+opt);
     //}, 100);
}

function out_capture2(opt){
     //setTimeout(function(){
	//var capture=
	document.getElementById('out_capture2').innerHTML = loadDocAsync('/get_capture.pl?action=out_key&'+opt);
     //}, 100);
}


function out_capture3(opt){
     //setTimeout(function(){
	//var capture=
	document.getElementById('out_capture3').innerHTML = loadDocAsync('/get_capture.pl?action=out_key&'+opt);
     //}, 100);
}





function openWindow(filename, w, h, winname)
{

    var nWidth;

        var nHeigth;

				if(filename.match(/\?/)){
					         filename += '&'+Math.random();
				}else{
					         filename += '?'+Math.random();
				}

        if (h) nHeigth = h; else nHeigth = 500;

        if (w) nWidth = w; else nWidth = 700;

        if (!winname) winname = "_blank";
        var desktop = window.open(filename, winname,

    "width="+nWidth+",height="+nHeigth+",toolbar=no,location=no,status=no,menubar=no,scrollbars=yes,resizable=yes");

};

function mousePageXY(e)
{
    if (!e) e = window.event;
    if (e.pageX || e.pageY)
    {
      mouse_x = e.pageX;
      mouse_y = e.pageY;
    }
    else if (e.clientX || e.clientY)
    {
      mouse_x = e.clientX + (document.documentElement.scrollLeft || document.body.scrollLeft) - document.documentElement.clientLeft;
      mouse_y = e.clientY + (document.documentElement.scrollTop || document.body.scrollTop) - document.documentElement.clientTop;
    }

}
document.onmousemove = function(e){var mCur =mousePageXY(e);}


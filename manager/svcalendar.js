    var months = new Array('Января','Февраля','Марта','Апреля','Мая','Июня','Июля','Августа','Сентября','Октября','Ноября','Декабря');
    var days_of_week = new Array('ПН','ВТ','СР','ЧТ','ПТ','СБ','ВС');
    var months_days = new Array(31,28,31,30,31,30,31,31,30,31,30,31);
    function init_calendar(save,par_obj,need_time)
    {

       // получаем год, месяц, день, часы, минуты и секунды
       var mix_str=document.getElementById(save).value;
      
       var list_data = mix_str.split (/[- :]/);
       var y,m,d,hours,mins,seconds;
       if(typeof eval(list_data[0]) == 'undefined'){y=0; } else y=list_data[0];       
       if(typeof eval(list_data[1]) == 'undefined'){m=0; } else m=list_data[1];
       if(typeof eval(list_data[2]) == 'undefined'){d=0; } else d=list_data[2];
       
       if(typeof eval(list_data[3]) == 'undefined'){hours=0; } else hours=list_data[3];
       if(typeof eval(list_data[4]) == 'undefined'){mins=0} else mins=list_data[4];
       if(typeof eval(list_data[5]) == 'undefined'){ seconds=0} else seconds=list_data[5];
             
       eval(save+'_OUT_DATS=0')
       id=document.getElementById(save)
       var div_id='calbody_'+save;
            
       if(par_obj)
         document.getElementById(par_obj).innerHTML+='<span id="'+div_id+'" class="calfield"></span>';
       else
         document.writeln('<span id="'+div_id+'" class="calfield"></span>');
		draw_calendar(save,y,m,d,hours,mins,seconds,need_time)
       
       return 0;
    }

    function draw_calendar(save,y,m,d,hours,mins,seconds,need_time)
    {
       
       var div_id='calbody_'+save;
       if ((y>0) && (m>0) && (d>0))
       {          
          m--;
          var dt = new Date(y, m, d,hours,mins,seconds);
       }
       else
          var dt = new Date();
        
       
       var curhour=dt.getHours();

              
       var curday=dt.getDate();
       var curmon=dt.getMonth();
       var curyear=dt.getYear();
       var hours=dt.getHours();
       var mins=dt.getMinutes();
       var seconds=dt.getSeconds();

       if(curyear<1900) curyear+=1900;
       
       var YEARLIST='<select id="'+save+'_changeyear" style="width: 60px;" onchange="changedate(\''+save+'\')">';
       for (i=1950; i<2020; i++)
       {
          var selected='';
          if(i==curyear) selected=' selected' 
          YEARLIST+='<option value='+i+selected+'>'+i+'</option>';
       }
       YEARLIST+='</select>';

       var MONLIST='<select id="'+save+'_changemon" style="width: 100px;" onchange="changedate(\''+save+'\')" style="margin-left: 6px;">';
       for (i=0; i<12; i++)
       {
          var selected='';
          if(i==curmon) selected=' selected';
          MONLIST+='<option value='+(i+1)+selected+'>'+months[i]+'</option>'
       }
       MONLIST+='</select>';

       if(curyear<1900){curyear+=1900}

       
       if(need_time){
       			// часы
       			
       			var HOURLIST='<select id="'+save+'_changehour" style="" onchange="changedate(\''+save+'\')" style="margin-left: 6px;">';
       		
       			for(i=0; i<24; i++){
          			var selected='';
          			if(i==hours) selected=' selected';       			
       					HOURLIST+='<option value='+(i)+selected+'>'+i+'</option>'	
       			}
       			HOURLIST+='</select>:';
       			
       			// минуты
       			var MINLIST='<select id="'+save+'_changemin" style="" onchange="changedate(\''+save+'\')" style="margin-left: 6px;">';
       			i=0;	
       			while(i<60)
       			{
          			var selected='';
          			if(i==mins) selected=' selected';       			
       					MINLIST+='<option value='+(i)+selected+'>'+i+'</option>'
       					i+=1;	
       			}
       			MINLIST+='</select>:';       	
       	
       			// секунды       	
       			var SECLIST='<select id="'+save+'_changesec" style="" onchange="changedate(\''+save+'\')" style="margin-left: 6px;">';
       			i=0;	
       			while(i<60)
       			{
          			var selected='';
          			if(i==seconds) selected=' selected';       			
       					SECLIST+='<option value='+(i)+selected+'>'+i+'</option>'
       					i+=1;	
       			}
       			SECLIST+='</select>';
       	
       			document.getElementById(div_id).innerHTML='<span id="'+save+'_changeday" style="border: 1px solid black; padding: 0 5px 0 5px;" OnClick="out_days(\''+save+'\')">'+curday+'</span>'+' '+MONLIST+' '+YEARLIST+' '+	HOURLIST+MINLIST+SECLIST;
       			curmon++;              
       			document.getElementById(save).value=curyear+'-'+curmon+'-'+curday + 
						' ' + hours + ':' + mins + ':' + seconds;
       }
       else{
       		
       		document.getElementById(div_id).innerHTML='<span id="'+save+'_changeday" style="border: 1px solid black; padding: 0 5px 0 5px;" OnClick="out_days(\''+save+'\')">'+curday+'</span>'+' '+MONLIST+' '+YEARLIST;
       		curmon++;
       		document.getElementById(save).value=curyear+'-'+curmon+'-'+curday;
       }      
       return;
    }

    function changedate(save,curday)
    {

       
       if(!curday) curday=document.getElementById(save+'_changeday').innerHTML;
       else
       {
         document.getElementById(save+'_changeday').innerHTML=curday;
       }

       var curmon=document.getElementById(save+'_changemon').value;
       var curyear=document.getElementById(save+'_changeyear').value;
       var max_days=get_last_day(curyear,curmon-1);
       if(max_days<curday)
       {
         curday=max_days
         document.getElementById(save+'_changeday').innerHTML=curday;
       }

       if(document.getElementById(save+'_changehour')==null){ // сохраняем дату без времени
       		document.getElementById(save).value=curyear+'-'+curmon+'-'+curday;
       }
       else{ // сохраняем дату вместе со временем
       		var curhour=document.getElementById(save+'_changehour').value;
       		var curmin=document.getElementById(save+'_changemin').value;
       		var cursec=document.getElementById(save+'_changesec').value;
       		document.getElementById(save).value=curyear+'-'+curmon+'-'+curday+' '+curhour+':'+curmin+':'+cursec;
       }
       
       if(typeof eval(save+'_OUT_DATS') == 'undefined'){eval(save+'_OUT_DATS=0')};

       if(eval(save+'_OUT_DATS==1'))
       {
          var parrent=document.getElementById('calbody_'+save);
          parrent.removeChild(document.getElementById(save+'_outdays_calendar'));          
          eval(save+'_OUT_DATS=0')
       }
       show_selects();
       return;
    }



    function out_days(save)
    {
        hide_selects(save);
        var parrent=document.getElementById('calbody_'+save);
        if(eval('typeof '+save+'_OUT_DATS') == 'undefined'){eval(save+'_OUT_DATS=0')};
        if(eval(save+'_OUT_DATS==0'))
        {

           var days_div=document.createElement('div');
           days_div.value= 'foo value';
           parrent.appendChild(days_div);
           days_div.style.position='absolute';
           days_div.style.top=mouse_y; //+0+'px';;
           //days_div.style.top+=5;
           days_div.style.left=mouse_x+5+'px';
           //days_div.style.border='1px solid black';
           days_div.style.background='#ffffff';
           //days_div.style.border='1px solid black';
           days_div.style.zindex='3';
           //days_div.style.width='200px';
           //days_div.style.height='200px';
           //days_div.style.border='1px solid black';
           days_div.id=save+'_outdays_calendar';

           // теперь выводим таблицу с календарём:
           var i=0;
           var string='<table class="caltable">';

           // наименования дней недели
           string+='<tr class="upline">';
           for (i=0; i<days_of_week.length; i++)
           {
               string+='<td>'+days_of_week[i]+'</td>';
           }
           string+='</tr>';

           var curday=document.getElementById(save+'_changeday').innerHTML;
           var curmon=(document.getElementById(save+'_changemon').value);
           curmon--;
           var curyear=(document.getElementById(save+'_changeyear').value);

           var iday=1;

           var fdate = new Date(curyear, curmon, 1);


           var fday=fdate.getDay();
           if(fday==0) fday=7
           var all_days=get_last_day(curyear,curmon); // всего дней в месяце
           var i=1;
           while(iday<=all_days)
           {
              string+='<tr>';
              for(var j=0; j<7; j++)
              {
                 var prday;
                 if(!(i%7) || !((i+1)%7)){cur_class=' class="holiday"'}else{cur_class=''}
                 if(iday<=all_days && i>=fday)
                   {prday=iday; iday++;}
                 else
                   {prday=''}
                 var date_mysql=curyear+'-'+(curmon+1)+'-'+i;
                 string+='<td'+cur_class+'><a href="javascript: changedate(\''+save+'\','+prday+')">'+prday+'</a></td>';
                 i++;
              }
              string+='</tr>';
           }
           string+='</table>';

           days_div.innerHTML=string;
           //OUT_DATS=1
           eval(save+'_OUT_DATS=1');
        }
        else
        { // убиваем слой
           show_selects();
           parrent.removeChild(document.getElementById(save+'_outdays_calendar'));
           eval(save+'_OUT_DATS=0');           
        }
        return;
    }

    function get_last_day(y,m)
    {
       if((m==1) && !(y%4))
       return 29;
       return months_days[m];
    }
    
function hide_selects(save)
{
//   hide all selects
     
     var allselects = document.getElementsByTagName("select");
     if(allselects != null)
     {
        for(i=0;i<allselects.length;i++)
        {
            //select_month = 'calendar_month_'+ cid;
            //select_year  = 'calendar_year_' + cid;

            re = /calendar_/i;
            allselects[i].style.display = 'none';


        }
     }
     document.getElementById(save+'_changeyear').style.display='';
     document.getElementById(save+'_changemon').style.display='';
}

function show_selects()
{
//   hide all selects
     var allselects = document.getElementsByTagName("select");
     if(allselects != null)
     {
        for(i=0;i<allselects.length;i++)
        {
            allselects[i].style.display = '';
        }
     }	
}

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

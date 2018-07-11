'RGB Neopixel ws2812b Clock
udp.begin 60123
onudp udpreceive


CLS
config$ =""
WORD.SETPARAM config$, "lowlightstart", "22"
WORD.SETPARAM config$, "lowlightend", "6"
WORD.SETPARAM config$, "lowlightpercent", "20"
WORD.SETPARAM config$, "maxlight", "100"
WORD.SETPARAM config$, "markers", "10"
word.setparam config$, "pulsemarkers","1"
word.setparam config$, "blender","1"

'check if clock.ini file exists
if FILE.EXISTS("clock.ini") = 0 then
 file.save "clock.ini",config$
 else
 config$ = file.read$("clock.ini")
 print "Read Config file"
 print config$
end if
 


lowlightstart$ = WORD.GETPARAM$(config$,"lowlightstart")
lowlightend$ = WORD.GETPARAM$(config$,"lowlightend")
lowlightpercent = val(WORD.GETPARAM$(config$,"lowlightpercent"))
llpercent$ = str$(lowlightpercent)
maxlight = val(WORD.GETPARAM$(config$,"maxlight"))
maxlightstr$ = str$(maxlight)
markers = val(WORD.GETPARAM$(config$,"markers"))
markersstr$ = str$(markers)
pulsemarkers = val(word.getparam$(config$,"pulsemarkers"))
blender = val(word.getparam$(config$,"blender"))
oldsec = 0
slices = 12 'update led 12 times a second 
lowlightactive = 0
llm$ = ""
t$ = ""

'Gamma Table to correct the coutput from leds
'https://hackaday.com/2016/08/23/rgb-leds-how-to-master-gamma-and-hue-for-perfect-brightness/
dim gma(12)
'data 0,3,5,13,25,42,63,90,123,161,205,255
data 1,4,11,20,34,52,74,100,132,168,209,255
For i=1 to 12
  read g
  gma(i) = g/255
Next i
  
dim cmpulse(12)
data 100,60,30,10,5,2,1,2,5,10,30,60   'data for pulsing 5 minute markers.
for i = 1 to 12
   read g
   cmpulse(i) = g/100
next i

data 0,0,0,0,1,1,1,2,3,3,4,5,7,8,9,11,13,15,17,19,21,24,26,29,32,35,39,42,46,50,54,58,62,67,72,77,82,87,93,98,104,110,117,123,130,137,144,151,159,166,174,182,191,199,208,217,226,236,245,255
dim blend(60)
for i = 1 to 60
read g
blend(i)= g/255
next i
 

neo.setup 15,60 'set up 60 led string to pin D8 = pin 15
for t = 0 to 119 'a startup animation !
neo.pixel t mod 60,255,1
neo.pixel (t +59)mod 60 , 0
next t


timer0 (1000/slices), mytimer     'timer will fire slices times a second, 12 times = 83ms
onhtmlchange htmlchange
OnHtmlReload Fill_Page
'autorefresh 1000    'update web page every second just in case
wait

 
mytimer:
  milli = millis
  t$ = time$

  h = val(left$(t$,2))   'get hours, min sec from time$
  m=val(mid$(t$,4,2))
  s=val(mid$(t$,7,2))
  
 
  'once a second do various checks
  
  if oldsec <> s then     'see if its a new second
    oldsec = s            'if it is then reset oldsec and reset fade to 1
    fade = 1              'fade will increase by 1 each time timer is called, ie from 1....12

    c = maxlight    'light brightness
    cm = markers     'brightness of the 5 minute markers

    'check if its low light time, only do once a second.
    if h >= val(lowlightstart$) or h <= val(lowlightend$) then
      c = int(c * lowlightpercent/100)
      cm = int(cm + lowlightpercent/100)
      llm$ = "Low light mode is on "
    else
      llm$ = "Low light mode is off"
    end if
  end if
  
  cmt = cm
  if pulsemarkers = 1 then
   cmt = cm * cmpulse(fade)
  endif 
  
  if blender = 0 then  'draw a normal clock
   neo.strip 0,59,0,1   'clear all 60 leds, use setting 1 at end of neopixel so doesnt update just yet
  
   for t = 0 to 59 step 5  'set the 5 minute markers
    neo.pixel t,cmt,cmt,cmt,1
   next t
  

   neo.pixel (h mod 12) *5,c,0,0,1   'set hour hand, but dont display yet 
   mp = neo.getpixel(m)  'get existing led color so can add blue to it, looks better,smoother
   mp = mp +c*256   'multiply c by 256 to get blue  color, 
   neo.pixel m,mp,1
  
   sfade = (s +1) mod 60 ' get the next seconds marker, mod 60 so it goes from 58>59>0>1 etc
   sp = neo.getpixel(sfade)
   sp = sp + (c*gma(fade))
   neo.pixel sfade,sp,1
   sp = neo.getpixel(s)
   sp = sp + (c*(1-gma(fade)))
   neo.pixel s,sp,0

  
  else
    'do a blended clock, where Red, green blue fade out behind the hands. 
   if fade = 1 then
    rr = 60 - ((h mod 12) * 5)
    mm = 60 - m
    ss = 60 - s
    for i = 1 to 60
     neo.pixel i-1,c*blend((rr+i)mod 60 +1),c*blend((mm+i)mod 60 +1),c*blend((ss+i)mod 60 +1),1
    next i
    print ss
   endif
   sfade = (s+59 ) mod 60 ' get the next seconds marker, mod 60 so it goes from 58>59>0>1 etc
   'show the next second hand position over 12 times per second.
   neo.pixel sfade,c*blend((rr+s)mod 60 +1),c*blend((mm+s)mod 60 +1),c*gma(fade)  
  endif
  fade = fade +  1
  'print millis - milli
return

htmlchange:

print str$(lowlightpercent)+"%"
llpercent$ = str$(lowlightpercent)
maxlightstr$ = str$(maxlight)
markersstr$ = str$(markers)
wlog "html change"
print "HTML CHANGE"
refresh
return


Jump1:
gosub savesettings
PRINT "Settings saved"

print textbox$(lowlightstart$)

REFRESH    ' refresh (update) the variables between the code and the html

Return

fill_page:
cls
a$ = ||
a$ = a$ + |LED Clock<br>|
a$ = a$ + "<div id='controls' style='display: table; margin-right:auto;margin-left:auto;text-align:center;>"



a$ = a$ + "<br>"
a$ = a$ + "<p>"+llm$+"</p>"
a$ = a$ + "<br> Start low light mode at "+textbox$(lowlightstart$)+"<br>"
a$ = a$ + "<br> End low light mode at "+textbox$(lowlightend$)+"<br>"
a$ = a$ + "<br> 5 Minute Markers  "+slider$(markers,0,200,1)+"  "+textbox$(markersstr$)+" <br>"
a$ = a$ +"<br> Pulse markers every second "+checkbox$(pulsemarkers)+"<br>"
a$ = a$ +"<br> Blend Effect "+checkbox$(blender)+"<br>"
a$ = a$ + "<br> Max Light  "+slider$(maxlight,5,255,1)+"  "+textbox$(maxlightstr$)+" <br>"
a$ = a$ + "<br> Low Light % "+slider$(lowlightpercent,0,100,1)+"  "+textbox$(llpercent$)+"% <br>"
a$ = a$ + "<br> Time is "+textbox$(t$)+"<br>"
a$ = a$ + BUTTON$("Save Settings",jump1,"but2")
print str$(lowlightpercent)
HTML a$
print a$
return

savesettings:
WORD.SETPARAM config$, "lowlightstart", lowlightstart$
WORD.SETPARAM config$, "lowlightend", lowlightend$
WORD.SETPARAM config$, "lowlightpercent", str$(lowlightpercent)
WORD.SETPARAM config$, "maxlight", str$(maxlight)
WORD.SETPARAM config$, "markers", str$(markers)
word.setparam config$, "blender",str$(blender)
print config$
file.save "clock.ini",config$
return


'my way of finding the IP of ESPs on the net. Send a 'whoisthere' to broadcast on port 60123
udpreceive:
myname$= "LEDClock"
udpr$ = udp.read$
if instr(udpr$,"whoisthere") <>0 then
  udp.reply "  "+myname$+" "+ WORD$(IP$,1)   ' return my name and the IP Address.
  end if
return

end

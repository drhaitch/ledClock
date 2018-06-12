CLS
config$ =""
WORD.SETPARAM config$, "lowlightstart", "22"
WORD.SETPARAM config$, "lowlightend", "6"
WORD.SETPARAM config$, "lowlightpercent", "20"
WORD.SETPARAM config$, "maxlight", "150"
WORD.SETPARAM config$, "markers", "10"
word.setparam config$, "pulsemarkers","1"

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
oldsec = 0
slices = 12 'update led 12 times a second 
lowlightactive = 0
llm$ = ""
t$ = ""

'Gamma Table to correct the coutput from leds
'https://hackaday.com/2016/08/23/rgb-leds-how-to-master-gamma-and-hue-for-perfect-brightness/
dim gma(12)
data 0,1,5,13,25,42,63,90,123,161,205,255
For i=1 to 12
  read g
  gma(i) = g/255
Next i
  
dim cmpulse(12)
data 100,60,30,10,5,2,1,2,5,10,30,60   'data for pulsing 5 minute parkers.
for i = 1 to 12
   read g
   cmpulse(i) = g/100
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
  
  
  for t= 0 to 59    'clear all 60 leds, use setting 1 at end of neopixel so doesnt update just yet
  neo.pixel t,0,1
  next t
  
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
  fade = fade +  1
 
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

a$ = ||
a$ = a$ + |LED Clock<br>|
a$ = a$ + "<br>"
a$ = a$ + "<p>"+llm$+"</p>"
a$ = a$ + "<br> Start low light mode at "+textbox$(lowlightstart$)+"<br>"
a$ = a$ + "<br> End low light mode at "+textbox$(lowlightend$)+"<br>"
a$ = a$ + "<br> 5 Minute Markers  "+slider$(markers,0,200,1)+"  "+textbox$(markersstr$)+" <br>"
a$ = a$ +"<br> Pulse markers every second "+checkbox$(pulsemarkers)+"<br>"
a$ = a$ + "<br> Max Light  "+slider$(maxlight,5,255,1)+"  "+textbox$(maxlightstr$)+" <br>"
a$ = a$ + "<br> Low Light % "+slider$(lowlightpercent,0,100,1)+"  "+textbox$(llpercent$)+"% <br>"
a$ = a$ + "<br> Time is "+textbox$(t$)+"<br>"
a$ = a$ + BUTTON$("Save Settings",jump1,"but2")
print str$(lowlightpercent)
HTML a$
return

savesettings:
WORD.SETPARAM config$, "lowlightstart", lowlightstart$
WORD.SETPARAM config$, "lowlightend", lowlightend$
WORD.SETPARAM config$, "lowlightpercent", str$(lowlightpercent)
WORD.SETPARAM config$, "maxlight", str$(maxlight)
WORD.SETPARAM config$, "markers", str$(markers)
print config$
file.save "clock.ini",config$
return

#Persistent
SetTimer, aqi_dash_update, 3600000

return

aqi_dash_update:
  
  FormatTime, TimeToMeet,,HHmm


if (TimeToMeet > 0700) {

        Run, "C:\Users\dkvale\Desktop\batch_r_aqi_dash_update.bat"
	      sleep, 60000

}

return

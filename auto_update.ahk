Loop,
{
Sleep, 3600000; check time every hour
if %A_Hour% > 5 ; 7 o clock
{
       Run, "C:\Users\dkvale\Desktop\batch_r_aqi_dash_update.bat"
       sleep, 60000

}
}

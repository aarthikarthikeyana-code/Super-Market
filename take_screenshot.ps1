$server = Start-Process python -ArgumentList "-m http.server 8089 --directory build/web" -PassThru
Start-Sleep -Seconds 5
$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
& $chrome --headless --disable-gpu --window-size=412,915 --screenshot="C:\Users\Admin\.gemini\antigravity\brain\574597a4-df32-4be0-98ba-aed8915bd168\customer_app_rendered.png" --virtual-time-budget=6000 "http://127.0.0.1:8089/#/customer-app"
& $chrome --headless --disable-gpu --window-size=412,915 --screenshot="C:\Users\Admin\.gemini\antigravity\brain\574597a4-df32-4be0-98ba-aed8915bd168\admin_app_rendered.png" --virtual-time-budget=6000 "http://127.0.0.1:8089/#/nummakadai"
Stop-Process -Id $server.Id -Force
Get-Item "C:\Users\Admin\.gemini\antigravity\brain\574597a4-df32-4be0-98ba-aed8915bd168\*_rendered.png"


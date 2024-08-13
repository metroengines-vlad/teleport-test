######### INIT CHECKS #########
###############################
# Ensure administrative privileges: Self-elevate the script if not running as admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    exit
}


# Get the process ID (PID) of the Teleport process (it is named "tsh")
$teleportProcess = Get-Process -Name "tsh" -ErrorAction SilentlyContinue

# Check if the process was found
if (-not $teleportProcess) {
    Write-Host "Teleport process not found. Plz run Teleport Connect first." -ForegroundColor Red
    Read-Host -Prompt "Press Enter to exit"
    exit
}


######### FIREWALL #########
############################
# to remove a firewall rule
Remove-NetFirewallRule -DisplayName "WSL" -ErrorAction SilentlyContinue

# open ports to be able to connect to all resources from WSL-->Host
New-NetFirewallRule -DisplayName "WSL" -Direction Inbound  -InterfaceAlias "vEthernet (WSL)"  -Action Allow

# check if the firewall rule persisted:
# Get-NetFirewallRule -DisplayName "WSL"


######### PORT FORWARDING TO WSL #########
##########################################
$teleportPID = $teleportProcess.Id
Write-Host "Teleport process ID: $teleportPID"

# Use netstat to get the port numbers associated with the Teleport process
$ports = netstat -ano | Select-String "^\s*TCP.*LISTEN.*$teleportPID$" | ForEach-Object {
    $_.ToString() -replace '^\s*TCP\s+(\S+):(\d+)\s.*', '$2'
}

if ($ports) {
    # HOUSEKEEPING: Get all existing port proxy rules and clear them out.
    # This might be a bit aggressive, but I'd rather not keep a bunch of port-forwarded junk unless it is needed.
    $regex = '(\d+\.\d+\.\d+\.\d+)\s+(\d+)\s+(\d+\.\d+\.\d+\.\d+)\s+(\d+)'
    $portProxyRules = netsh interface portproxy show v4tov4 | Select-String $regex

    # Loop through each rule and remove it
    foreach ($rule in $portProxyRules) {
        # Extract listening port and listening address
        if ($rule -match $regex) {
            $listenAddress = $matches[1]
            $listenPort = $matches[2]
            $connectAddress = $matches[3]
            $connectPort = $matches[4]
            Write-Host "Removing proxied $listenPort -> $connectPort on $connectAddress."

            # Remove the port proxy rule
            netsh interface portproxy delete v4tov4 listenport=$listenPort listenaddress=0.0.0.0
        }
    }
    Write-Host "All port proxy rules have been removed." -ForegroundColor Green

    Write-Host "Add Teleport port proxies:"
    $ports | ForEach-Object {
        # port-forward teleported db(s) to be visible from WSL
        $PORT=$_
        netsh interface portproxy add v4tov4 listenport=$PORT listenaddress=0.0.0.0 connectport=$PORT connectaddress=127.0.0.1
        Write-Host "Forwarded: $PORT" -ForegroundColor Green
    }
    # check what is forwarded to WSL
    netsh interface portproxy show v4tov4
} else {
    Write-Host "No active ports found for the Teleport process." -ForegroundColor Red
}

Write-Host "Done. You may now close the powershell window after confirming the output above."
Read-Host -Prompt "Press Enter to exit"

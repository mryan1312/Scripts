#requires -version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ----------------------- Settings -----------------------
$BaseLogDir  = 'C:\SecurityLogs\FailedLogons'
$StateDir    = 'C:\ProgramData\FailedLogonMonitor'
$StateFile   = Join-Path $StateDir 'state.json'

# Watch these logs. Add 'ForwardedEvents' if using WEF.
$LogsToWatch = @('Security')
# $LogsToWatch = @('Security','ForwardedEvents')  # uncomment if you use WEF

# Failed/lockout-related events
$EventIds    = @(4625, 4771, 4776, 4740)

# Ignore noisy source IPs (ex: Arctic Wolf appliance IPs)
$IgnoreIpAddresses = @(
    '10.10.10.50'
)

# Ignore noisy target users (service accounts, scanners, etc.)
$IgnoreTargetUsers = @(
    'netwrixadmin'
)

# Polling interval (seconds)
$PollSeconds = 5

# DNS cache cap (prevents endless growth)
$MaxDnsCacheEntries = 5000

# ----------------------- Helpers -----------------------
function Ensure-Dir([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
    }
}

function Normalize-User([string]$u) {
    if (-not $u) { return $null }
    $u = $u.Trim()

    # Strip DOMAIN\ prefix if present
    if ($u -match '^[^\\]+\\(.+)$') { $u = $Matches[1] }

    $u.ToLowerInvariant()
}

$IgnoreTargetUsersNormalized = @($IgnoreTargetUsers | ForEach-Object { Normalize-User $_ })

# Simple in-memory DNS cache: IP -> hostname (or $null)
$script:IpDnsCache = @{}

function Resolve-IpHostname([string]$ip) {
    if (-not $ip) { return $null }

    if ($script:IpDnsCache.ContainsKey($ip)) {
        return $script:IpDnsCache[$ip]
    }

    $hostname = $null
    try {
        if (Get-Command Resolve-DnsName -ErrorAction SilentlyContinue) {
            $ptr = Resolve-DnsName -Name $ip -Type PTR -ErrorAction Stop | Select-Object -First 1
            if ($ptr -and $ptr.NameHost) { $hostname = [string]$ptr.NameHost }
        } else {
            $entry = [System.Net.Dns]::GetHostEntry($ip)
            if ($entry -and $entry.HostName) { $hostname = [string]$entry.HostName }
        }
    } catch {
        $hostname = $null
    }

    if ($hostname -and $hostname.EndsWith('.')) { $hostname = $hostname.TrimEnd('.') }

    $script:IpDnsCache[$ip] = $hostname
    if ($script:IpDnsCache.Count -gt $MaxDnsCacheEntries) { $script:IpDnsCache.Clear() }

    return $hostname
}

function Get-LogFilePath([datetime]$dt) {
    $year  = $dt.ToString('yyyy')
    $month = $dt.ToString('MM')
    $day   = $dt.ToString('yyyy-MM-dd')

    $dir = Join-Path $BaseLogDir (Join-Path $year $month)
    Ensure-Dir $dir

    # Pretty-printed JSON records are multi-line, so this is not JSONL anymore.
    Join-Path $dir "FailedLogons_$day.json"
}

function Load-State {
    try {
        if (Test-Path -LiteralPath $StateFile) {
            $raw = Get-Content -LiteralPath $StateFile -Raw | ConvertFrom-Json

            # Convert PSCustomObject -> hashtable for lastRecordId so .ContainsKey works
            $hash = @{}
            if ($raw.lastRecordId) {
                foreach ($p in $raw.lastRecordId.PSObject.Properties) {
                    $hash[$p.Name] = [long]$p.Value
                }
            }

            return [pscustomobject]@{
                lastRecordId = $hash
            }
        }
    } catch { }

    return [pscustomobject]@{
        lastRecordId = @{}
    }
}

function Save-State($state) {
    Ensure-Dir $StateDir
    ($state | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath $StateFile -Encoding UTF8
}

function Get-EventDataMap([xml]$eventXml) {
    $map = @{}
    $nodes = $eventXml.Event.EventData.Data
    if ($null -eq $nodes) { return $map }

    foreach ($n in @($nodes)) {
        $name = [string]$n.Name
        if ([string]::IsNullOrWhiteSpace($name)) { continue }

        $val = $null
        try {
            $val = [string]$n.InnerText
        } catch {
            try { $val = [string]$n.'#text' } catch { $val = $null }
        }

        $map[$name] = $val
    }

    return $map
}

function Normalize-Ip([string]$ip) {
    if (-not $ip) { return $null }
    $ip = $ip.Trim()
    if ($ip -like '::ffff:*') { $ip = $ip.Substring(7) }
    if ($ip -eq '-' -or $ip.Length -eq 0) { return $null }
    $ip
}

function Normalize-Record([xml]$x) {
    $sys  = $x.Event.System
    $data = Get-EventDataMap $x

    $eventId     = [int]$sys.EventID
    $timeCreated = [datetime]$sys.TimeCreated.SystemTime

    $obj = [ordered]@{
        timeCreated = $timeCreated.ToString('o')
        computer    = [string]$sys.Computer
        logName     = [string]$sys.Channel
        provider    = [string]$sys.Provider.Name
        eventId     = $eventId
        recordId    = [long]([string]$sys.EventRecordID)
        category    = ''
        ipAddress   = $null
        ipHostname  = $null
        eventData   = $data
    }

    switch ($eventId) {
        4625 {
            $obj.category      = 'FailedLogon'
            $obj.targetUser    = $data['TargetUserName']
            $obj.targetDomain  = $data['TargetDomainName']
            $obj.logonType     = $data['LogonType']
            $obj.workstation   = $data['WorkstationName']
            $obj.process       = $data['ProcessName']
            $obj.authPackage   = $data['AuthenticationPackageName']
            $obj.status        = $data['Status']
            $obj.subStatus     = $data['SubStatus']
            $obj.failureReason = $data['FailureReason']
            $obj.ipAddress     = Normalize-Ip $data['IpAddress']
        }
        4771 {
            $obj.category     = 'KerberosPreAuthFailed'
            $obj.targetUser   = $data['TargetUserName']
            $obj.targetDomain = $data['TargetDomainName']
            $obj.serviceName  = $data['ServiceName']
            $obj.status       = $data['Status']
            $obj.failureCode  = $data['FailureCode']

            $ip = if ($data.ContainsKey('ClientAddress') -and $data['ClientAddress']) {
                $data['ClientAddress']
            } else {
                $data['IpAddress']
            }
            $obj.ipAddress = Normalize-Ip $ip
        }
        4776 {
            $obj.category    = 'NTLMAuthFailed'
            $obj.targetUser  = $data['TargetUserName']
            $obj.workstation = $data['Workstation']
            $obj.status      = $data['Status']
        }
        4740 {
            $obj.category       = 'AccountLockout'
            $obj.targetUser     = $data['TargetUserName']
            $obj.callerComputer = $data['CallerComputerName']
        }
        default {
            $obj.category = 'Other'
        }
    }

    return $obj
}

function Write-JsonRecord([object]$obj) {
    $dt   = [datetime]::Parse($obj.timeCreated)
    $path = Get-LogFilePath $dt

    $json = $obj | ConvertTo-Json -Depth 8

    Add-Content -LiteralPath $path -Value $json -Encoding UTF8
    Add-Content -LiteralPath $path -Value "" -Encoding UTF8
}

function Build-FilterXml([string]$logName, [long]$lastRecordId, [int[]]$ids) {
    $idsOr = ($ids | ForEach-Object { "EventID=$_" }) -join " or "
@"
<QueryList>
  <Query Id="0" Path="$logName">
    <Select Path="$logName">*[System[($idsOr) and (EventRecordID &gt; $lastRecordId)]]</Select>
  </Query>
</QueryList>
"@
}

# ----------------------- Start -----------------------
Ensure-Dir $BaseLogDir
Ensure-Dir $StateDir

$state = Load-State

foreach ($log in $LogsToWatch) {
    if (-not $state.lastRecordId.ContainsKey($log)) {
        $state.lastRecordId[$log] = 0
    }
}

while ($true) {
    try {
        foreach ($log in $LogsToWatch) {
            $last = [long]$state.lastRecordId[$log]
            $filterXml = Build-FilterXml -logName $log -lastRecordId $last -ids $EventIds

            # Get-WinEvent is inconsistent:
            # - sometimes returns nothing
            # - sometimes returns a single record object
            # - sometimes returns an array
            # - sometimes throws "No events were found..." instead of returning empty
            $events = @()
            try {
                $events = @(Get-WinEvent -FilterXml $filterXml -ErrorAction Stop | Sort-Object RecordId)
            } catch {
                if ($_.Exception.Message -match 'No events were found that match the specified selection criteria') {
                    $events = @()
                } else {
                    throw
                }
            }

            foreach ($ev in $events) {
                $x = [xml]$ev.ToXml()
                $obj = Normalize-Record $x

                # ---- Filters (cheap first) ----

                # Ignore noisy target users (case-insensitive)
                if ($obj.targetUser) {
                    $tu = Normalize-User ([string]$obj.targetUser)
                    if ($tu -and ($IgnoreTargetUsersNormalized -contains $tu)) {
                        $state.lastRecordId[$log] = [long]$obj.recordId
                        continue
                    }
                }

                # Ignore noisy source IPs (Arctic Wolf etc.)
                if ($obj.ipAddress -and ($IgnoreIpAddresses -contains [string]$obj.ipAddress)) {
                    $state.lastRecordId[$log] = [long]$obj.recordId
                    continue
                }

                # ---- Enrichment (expensive) ----
                if ($obj.ipAddress) {
                    $obj.ipHostname = Resolve-IpHostname -ip ([string]$obj.ipAddress)
                }

                Write-JsonRecord -obj $obj
                $state.lastRecordId[$log] = [long]$obj.recordId
            }

            if ($events.Length -gt 0) { Save-State $state }
        }
    }
    catch {
        try {
            $errPath = Join-Path $StateDir 'monitor_errors.log'
            Add-Content -LiteralPath $errPath -Value ("{0} {1}" -f (Get-Date).ToString('o'), $_.Exception.ToString()) -Encoding UTF8
        } catch { }
    }

    Start-Sleep -Seconds $PollSeconds
}
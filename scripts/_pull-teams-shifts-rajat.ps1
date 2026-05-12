# Pull MS Teams Shifts for Rajat Kumar, May 2026, from the "Tech India" team
# using the Teams-Connector app (Schedule.Read.All + Group.Read.All). Read-only.

$keysFile = "C:\Users\rjain\OneDrive - Technijian, Inc\Documents\VSCODE\keys\teams-connector.md"
$raw = Get-Content $keysFile -Raw
$clientId = [regex]::Match($raw, 'App Client ID:\*\*\s*(\S+)').Groups[1].Value
$tenantId = [regex]::Match($raw, 'Tenant ID:\*\*\s*(\S+)').Groups[1].Value
$secret   = [regex]::Match($raw, 'Client Secret:\*\*\s*(\S+)').Groups[1].Value

$tok = (Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -Method POST -Body @{
    grant_type="client_credentials"; client_id=$clientId; client_secret=$secret; scope="https://graph.microsoft.com/.default"
} -ContentType "application/x-www-form-urlencoded").access_token
$H = @{ Authorization = "Bearer $tok"; ConsistencyLevel = "eventual" }

function GraphAll($url) {
    $out = @()
    while ($url) { $r = Invoke-RestMethod -Uri $url -Headers $H -Method GET; if ($r.value){$out+=$r.value}else{return $r}; $url=$r.'@odata.nextLink' }
    return $out
}

# Resolve Rajat user ids
$users = GraphAll "https://graph.microsoft.com/v1.0/users?`$filter=startswith(displayName,'Rajat')&`$select=id,displayName,userPrincipalName,jobTitle&`$top=50"
Write-Host "=== Directory users matching 'Rajat' ===" -ForegroundColor Cyan
$rajatIds=@{}
foreach($u in $users){ Write-Host ("  {0}  {1}  <{2}>  {3}" -f $u.id,$u.displayName,$u.userPrincipalName,$u.jobTitle); $rajatIds[$u.id]=$u.displayName }

$tzIST=[System.TimeZoneInfo]::FindSystemTimeZoneById("India Standard Time")
$tzPST=[System.TimeZoneInfo]::FindSystemTimeZoneById("Pacific Standard Time")

# Teams to inspect (Tech India is the obvious one; also peek at Admin-Support / ClientPortal in case)
$candidateTeams = @(
  @{id="89b88b17-d218-4b69-9d08-0b44d33b52af"; name="Tech India"},
  @{id="cef8aca0-3ed4-4399-bf0b-bf26068c9094"; name="Admin-Support"},
  @{id="4245c52e-21a9-4416-bccf-2343614c3a9e"; name="Technijian"}
)

$startWin=[datetime]::Parse("2026-04-29T00:00:00Z").ToUniversalTime()
$endWin=[datetime]::Parse("2026-06-03T00:00:00Z").ToUniversalTime()

foreach($t in $candidateTeams){
  $sched=$null
  try { $sched = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/teams/$($t.id)/schedule" -Headers $H -Method GET } catch { Write-Host ("[{0}] no schedule provisioned" -f $t.name) -ForegroundColor DarkGray; continue }
  Write-Host ""
  Write-Host ("=== SCHEDULE: {0}  provisionStatus={1}  timeZone={2} ===" -f $t.name,$sched.provisionStatus,$sched.timeZone) -ForegroundColor Green
  if ($sched.provisionStatus -ne 'completed') { continue }

  # Pull shifts in window — Shifts API needs a date filter on sharedShift, else 500s
  $sd="2026-04-25T00:00:00.000Z"; $ed="2026-06-05T00:00:00.000Z"
  $shifts=@()
  $filt=[uri]::EscapeDataString("sharedShift/startDateTime ge $sd and sharedShift/endDateTime le $ed")
  try {
    $url="https://graph.microsoft.com/v1.0/teams/$($t.id)/schedule/shifts?`$filter=$filt&`$top=100"
    $shifts=GraphAll $url
  } catch {
    Write-Host "  filtered shifts fetch error ($($_.Exception.Message)); trying unfiltered..." -ForegroundColor DarkYellow
    try { $shifts=GraphAll "https://graph.microsoft.com/v1.0/teams/$($t.id)/schedule/shifts?`$top=100" } catch { Write-Host "  unfiltered also failed: $($_.Exception.Message)"; continue }
  }
  Write-Host ("  fetched {0} shift records total" -f $shifts.Count)
  $rows=@()
  foreach($s in $shifts){
    if ([string]::IsNullOrEmpty($s.userId)) { continue }
    if (-not $rajatIds.ContainsKey($s.userId)) { continue }
    $sh=$s.sharedShift; if(-not $sh){$sh=$s.draftShift}; if(-not $sh){continue}
    $st=[datetimeoffset]::Parse($sh.startDateTime).UtcDateTime
    $en=[datetimeoffset]::Parse($sh.endDateTime).UtcDateTime
    if ($st -lt $startWin -or $st -gt $endWin) { continue }
    $stIST=[System.TimeZoneInfo]::ConvertTimeFromUtc($st,$tzIST); $enIST=[System.TimeZoneInfo]::ConvertTimeFromUtc($en,$tzIST)
    $stPST=[System.TimeZoneInfo]::ConvertTimeFromUtc($st,$tzPST); $enPST=[System.TimeZoneInfo]::ConvertTimeFromUtc($en,$tzPST)
    $rows+=[pscustomobject]@{
      UTC=$st.ToString("MM-dd ddd HH:mm")+"->"+$en.ToString("HH:mm")
      PST=$stPST.ToString("MM-dd HH:mm")+"->"+$enPST.ToString("MM-dd HH:mm")
      IST=$stIST.ToString("MM-dd HH:mm")+"->"+$enIST.ToString("MM-dd HH:mm")
      Hrs=[math]::Round(($en-$st).TotalHours,2)
      Label=$sh.displayName; Theme=$sh.theme; Who=$rajatIds[$s.userId]
    }
  }
  if($rows.Count -eq 0){ Write-Host "  (no Rajat shifts in window for this team)"; continue }
  $rows | Sort-Object UTC | Format-Table UTC,Hrs,PST,IST,Label,Theme,Who -AutoSize -Wrap | Out-String -Width 200 | Write-Host

  # India 3rd/night shift = 10:30 PM - 7:30 AM IST. Flag by IST start hour band or label.
  $nights = $rows | Where-Object { $h=[int]($_.IST.Substring(6,2)); ($h -ge 21 -or $h -le 2) -or ($_.Label -match 'night|3rd|third') }
  $may = $nights | Where-Object { $_.IST -match '^05-' }
  Write-Host ("  --> Rajat shifts in window: {0}.  Night/3rd-shift (IST 22:30-07:30 band): {1}.  Of those with IST start date in MAY 2026: {2}." -f $rows.Count,($nights|Measure-Object).Count,($may|Measure-Object).Count) -ForegroundColor Yellow
  if($nights){ Write-Host "  Night-shift list:"; $nights | Sort-Object UTC | ForEach-Object { Write-Host ("    IST {0}  ({1}h)  '{2}'  theme={3}" -f $_.IST,$_.Hrs,$_.Label,$_.Theme) } }
}
Write-Host ""
Write-Host "DONE (read-only)."

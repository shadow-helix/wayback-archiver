param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("Archive", "Search")]
  $Action,
  [Parameter(ParameterSetName = 'AsFile', Mandatory = $true)]
  [Parameter(ParameterSetName = 'AsURL', Mandatory = $false)]
  [string]$FilePath,
  [Parameter(ParameterSetName = 'AsFile', Mandatory = $false)]
  [Parameter(ParameterSetName = 'AsURL', Mandatory = $true)]
  [string]$Url,
  [string]$OutputFile
)

if ($Action -ceq "Archive") {

  if ($FilePath) {
    $urlList = Get-Content $FilePath
  }
  elseif ($Url) {
    $urlList = $Url
  }

  $archiveRegister = foreach ($urlToArchive in $urlList) {

    if ($archived -or $failed) {
      Clear-Variable -Name archived, failed -ErrorAction SilentlyContinue
      Start-Sleep -Seconds 10 # Ten second sleep to get around the rate-limit
    }

    $body = @{
      "capture_all" = "on"
      "url"         = $urlToArchive
    }
    try {
      $saveResult = Invoke-RestMethod "https://web.archive.org/save/" -Method POST -Body $body
      $jobID = $saveResult | select-string -pattern "spn.watchJob\(\`".*`"," | foreach { $_.matches }[0] | select -expand value
      $jobID = ($jobID -split "`"")[1]
      if ($jobID) {
        $archived = $true
        Write-Host "[+] $urlToArchive successfully submitted for archive." -ForegroundColor Green
      }
      else {
        Write-Host "[-] $urlToArchive failed submission for archive." -ForegroundColor red
        $failed = $true
      }
    }
    catch {
      [PSCustomObject]@{
        "URL"            = $urlToArchive
        "Archive Status" = "failed to archive"
      }
      Write-Host "[-] $urlToArchive failed submission for archive." -ForegroundColor red
      $failed = $true
      continue
    }

    if ($archived -eq $true) {
      [PSCustomObject]@{
        "URL"            = $urlToArchive
        "Archive Status" = "success"
      }
    }
  }
  if ($OutputFile) {
    $archiveRegister | Export-Csv $OutputFile -NoTypeInformation
  }
}


if ($Action -ceq "Search") {

  if ($FilePath) {
    $urlList = Get-Content $FilePath
  }
  elseif ($Url) {
    $urlList = $Url
  }

  $resultsHeaders = @{
    "Referer" = "https://web.archive.org/"
  }

  $archiveResults = foreach ($url in $urlList) {
    if ($archiveURL) {
      Start-Sleep -Seconds 5
    }
    Clear-Variable -Name encodedURL, archiveSearch, archiveTimestamp, archivalStatus, archiveURL -ErrorAction SilentlyContinue
  
    try {
      #encode the URL
      $encodedURL = [System.Web.HTTPUtility]::UrlEncode($url)
      $archiveSearch = Invoke-RestMethod "https://web.archive.org/__wb/sparkline?output=json&url=$encodedURL&collection=web" -Headers $resultsHeaders
      Write-Host "[+] $url found on Wayback Machine" -ForegroundColor Green
      $archiveTimestamp = $archiveSearch.last_ts
      if ($archiveTimestamp) {
        $archivalStatus = "success"
        $archiveURL = "https://web.archive.org/web/$archiveTimestamp/$url"
        Write-Host "    $archiveURL" -ForegroundColor Green
      }
      else {
        $archivalStatus = "error"
        $archiveURL = "error"
      }
    }
    catch {
      Write-Host "[-] $url not found" -ForegroundColor Red
      $archivalStatus = "error"
      $archiveURL = "error"
      continue
    }
  
    [PSCustomObject]@{
      "URL"         = $url
      "Status"      = $archivalStatus
      "Archive URL" = $archiveURL
    }
  
  }
  if ($OutputFile) {
    $archiveResults | Export-Csv $OutputFile -NoTypeInformation
  }
}

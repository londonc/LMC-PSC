<#
.SYNOPSIS
Powershell script to search through Office 365 Compliance Center and delete emails. 
   Author: London Crosby
   Created: <06-27-2018>
#>

$CurrentDate = Get-Date
$SearchDate = $CurrentDate.ToString()

Write-Output '### SEARCH AND REMOVE EMAILS MATCHING THE FOLLOWING CRITERIA ###'
$SearchParamFrom = Read-Host -Prompt 'Email from'
$SearchName = "$SearchParamFrom - $SearchDate"

# Prevent user from accidentially entering in nothing. 
$SearchParamSubject = ""
While (!$SearchParamSubject){
    $SearchParamSubject = Read-Host -Prompt 'Email Subject Line'  
}

#
If ($SearchParamSubject.Contains("!")){
    Write-Output "WARNING: Contains special character that may present a problem... removing from string"
    # '!' character can cause problems. Probably ASCII/Unicode handling issue. 
    $SearchParamSubject = $SearchParamSubject -replace '!','*'
}

# Narrow the scope a bit
$SearchParamDate = Read-Host -Prompt 'Email sent after (ie YYYY-MM-DD - Default 1 Month)'
If (!$SearchParamDate) { 
    $SearchParamDate = $CurrentDate.AddMonths(-1).ToString('yyy-MM-dd')
}

$EOLogin = 'admin@example.com'
$EOPassFile = 'Path-to-encryped-password.txt'

# If doesn't exist then let's set some up!
If (!(Test-Path $EOPassFile)) { 
    $GetPass = Read-Host -Prompt "Enter password: " -AsSecureString
    $GetPass | ConvertFrom-SecureString | Out-File $EOPassFile 
}

$EOCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $EOLogin, (Get-Content $EOPassFile | ConvertTo-SecureString)
$EOCCSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.compliance.protection.outlook.com/powershell-liveid/ -Credential $EOCredentials -Authentication Basic -AllowRedirection

Import-PSSession $EOCCSession
New-ComplianceSearch -Name "$SearchName" -ContentMatchQuery "(c:c)(subjecttitle:$SearchParamSubject)(from:$SearchParamFrom)(sent>$SearchParamDate)‎" -Description "Initiated from $env:COMPUTERNAME" -ExchangeLocation All -AllowNotFoundExchangeLocationsEnabled $true

Start-ComplianceSearch -Identity "$SearchName"

# Be nice and wait for search to complete 
Write-Output '### WAITING FOR SEARCH TO COMPLETE... ###'
$SearchProgress = Get-ComplianceSearch -Identity "$SearchName" | Select Items, Status
While ($SearchProgress.Status -ne 'Completed'){
    Start-Sleep -s 1
    $SearchProgress = Get-ComplianceSearch -Identity "$SearchName" | Select Items, Status
}

If($SearchProgress.Items -gt 0){
    New-ComplianceSearchAction -SearchName "$SearchName" -Purge -PurgeType SoftDelete -Verbose

    # Wait and check progress of purge 
    $PurgeProgress = Get-ComplianceSearchAction -Identity $SearchName"_purge"
    While($PurgeProgress.Status -ne 'Completed'){
        Start-Sleep -s 1
        $PurgeProgress = Get-ComplianceSearchAction -Identity $SearchName"_purge"
    }
    Write-Out "$SearchProgress.Items deleted"

} else {
    Write-Output "ERROR: No items found! Check your search parameters. "
}

# EOL
Write-Output '### END OF LINE ###'
Remove-PSSession $EOCCSession

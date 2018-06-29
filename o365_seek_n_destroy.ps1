<#
.SYNOPSIS
Powershell script to search through Office 365 Compliance Center and delete emails. 
   Author: London Crosby
   Created: <06-27-2018>
#>

$CurrentDate = Get-Date
$SearchDate = $CurrentDate.ToString()


Write-Output '### SEARCH AND REMOVE EMAILS MATCHING THE FOLLOWING CRITERIA ###'
$SearchParamFrom = Read-Host -Prompt 'From'
$SearchName = "$SearchParamFrom - $SearchDate"

# Prevent user from accidentially entering in nothing. 
$SearchParamSubject = ""
While (!$SearchParamSubject){
    $SearchParamSubject = Read-Host -Prompt 'Subject Line'  
}


# Narrow the scope a bit with some guard rails. Need to replace with regex
$SearchParamDate = ""
While (($SearchParamDate.Length -lt 10) -or ($SearchParamDate.Length -gt 10)){
    $SearchParamDate = Read-Host -Prompt 'Sent after (Format must be YYYY-MM-DD - Default 1 Month)'

    If ($SearchParamDate.Length -eq 0) { 
        $SearchParamDate = $CurrentDate.AddMonths(-1).ToString('yyyy-MM-dd')
    }
}

$EOLogin = 'admin@example.com'
$EOPassFile = 'Path-to-encryped-password.txt'

# If doesn't exist then let's set some up!
If (!(Test-Path $EOPassFile)) { 
    $GetPass = Read-Host -Prompt 'Enter password: ' -AsSecureString
    $GetPass | ConvertFrom-SecureString | Out-File $EOPassFile 
}

$EOCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $EOLogin, (Get-Content $EOPassFile | ConvertTo-SecureString)
$EOCCSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.compliance.protection.outlook.com/powershell-liveid/ -Credential $EOCredentials -Authentication Basic -AllowRedirection

Import-PSSession $EOCCSession

function EOL {
    Write-Output '### END OF LINE ###'
    Remove-PSSession $EOCCSession
    Exit
}


$SearchQuery = "(c:c)(subjecttitle:$SearchParamSubject)(from:$SearchParamFrom)(sent>$SearchParamDate)‎"
# Seen powershell do funny shit with hidden characters
$SearchQuery = $SearchQuery -replace '[^\w\(\)\:\@\.\>\-/ ]',''


New-ComplianceSearch -Name $SearchName -ContentMatchQuery $SearchQuery -Description "Initiated from $env:COMPUTERNAME" -ExchangeLocation All -AllowNotFoundExchangeLocationsEnabled $true


Write-Output '### STARTING SEARCH ###'
Start-ComplianceSearch -Identity $SearchName;

# Be nice and wait for search to complete 
Write-Output '### WAITING FOR SEARCH TO COMPLETE... ###'
$SearchProgress = Get-ComplianceSearch -Identity $SearchName | Select Items, Status

While ($SearchProgress.Status -ne 'Completed'){
    Start-Sleep -s 1
    $SearchProgress = Get-ComplianceSearch -Identity $SearchName | Select Items, Status
}

$SearchFound = $SearchProgress.Items
Write-Output '### SEARCH COMPLETE ###'


# Get error count for preventing rolling errors
$ErrorCount = $Error.Count

If($SearchProgress.Items -gt 0){
    Write-Output "### $SearchFound ITEMS FOUND. STARTING PURGE... ###"
    New-ComplianceSearchAction -SearchName $SearchName -Purge -PurgeType SoftDelete -Verbose

        $PurgeProgress = Get-ComplianceSearchAction -Identity $SearchName"_purge"

        
        If($ErrorCount -eq $Error.Count){
            While($PurgeProgress.Status -ne 'Completed'){
               Write-Output '### WAITING FOR PURGE TO COMPLETE... ###'
                Start-Sleep -s 1
                $PurgeProgress = Get-ComplianceSearchAction -Identity $SearchName"_purge"
            }
            Write-Output "$SearchFound itmes deleted."

        } else {
            Write-Output 'ERROR: User may have selected not to purge or something went wrong. See output for debugging. '
            EOL
        }

} else {
    Write-Output 'ERROR: No items found! Check your search parameters. '
}

EOL

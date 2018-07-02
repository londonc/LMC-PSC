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
#$SearchParamFrom = $SearchParamFrom -replace '[^\w\(\)\:\@\.\>\-\ \"\'']',''

$SearchName = "$SearchParamFrom - $SearchDate"

# Prevent user from accidentially entering nothing. 
$SearchParamSubject = ''
While (!$SearchParamSubject){
    $SearchParamSubject = Read-Host -Prompt 'Subject Line'  
}

# Narrow the scope a bit with some guard rails.
$SearchParamDate = ''
While ($SearchParamDate -notmatch '\d\d\d\d\-\d\d\-\d\d' ){
    $SearchDefaultDate = $CurrentDate.AddMonths(-1).ToString('yyyy-MM-dd')
    $SearchParamDate = Read-Host -Prompt "Sent after YYYY-MM-DD (Default is $SearchDefaultDate)"

    If ($SearchParamDate.Length -eq 0) { 
        $SearchParamDate = $SearchDefaultDate
    }
}

$EOLogin = 'admin@example.com'
$EOPassFile = 'C:\Path\to\encryped\password.txt'

# If doesn't exist then let's set some up!
If (!(Test-Path $EOPassFile)) { 
    $GetPass = Read-Host -Prompt 'Enter password: ' -AsSecureString
    $GetPass | ConvertFrom-SecureString | Out-File $EOPassFile 
}

$EOCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $EOLogin, (Get-Content $EOPassFile | ConvertTo-SecureString)
$EOCCSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.compliance.protection.outlook.com/powershell-liveid/ -Credential $EOCredentials -Authentication Basic -AllowRedirection

Import-PSSession $EOCCSession

Function Purge {
    [cmdletbinding(SupportsShouldProcess)]
    Param()
    
    If ($PSCmdlet.ShouldContinue("$SearchFound items found. Do you wish to purge them?","Staring Purge")) {

        # Get error count for preventing rolling errors
        $ErrorCount = $Error.Count

        New-ComplianceSearchAction -SearchName $SearchName -Purge -PurgeType SoftDelete -Verbose

        $PurgeProgress = Get-ComplianceSearchAction -Identity $SearchName"_purge"
        
        If($ErrorCount -eq $Error.Count){
             While($PurgeProgress.Status -ne 'Completed'){
                   Write-Output '### WAITING FOR PURGE TO COMPLETE... ###'
                    Start-Sleep -s 1
                    $PurgeProgress = Get-ComplianceSearchAction -Identity $SearchName"_purge"
             }

         Write-Output "$SearchFound items deleted."

        } else {
            Write-Output 'ERROR: Something went wrong. See output for debugging. '
            EOL
        }
        
    } else {
        Write-Output "You're the boss. "
    }
}

function EOL {
    Write-Output '### END OF LINE ###'
    Remove-PSSession $EOCCSession
    Exit
}


$SearchQuery = "(c:c)(subjecttitle:`"$SearchParamSubject`")(from:$SearchParamFrom)(sent>$SearchParamDate)‎"
# Seen powershell do funny shit with hidden characters
$SearchQuery = $SearchQuery -replace '[^\w\(\)\:\@\.\>\-\ \!\"\'']',''


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

If($SearchProgress.Items -gt 0){
    Purge

} else {
    Write-Output 'ERROR: 0 items found! Check your search parameters. '
}

EOL

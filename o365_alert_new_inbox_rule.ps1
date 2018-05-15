<#
.SYNOPSIS
Powershell script to parse through Office 365 logs every 15 minutes and sent out an email alert if supciious rule found. 
.NOTES
   Author: London Crosby
   Created: <05-14-2018>
#>

# 
$ExoLogin = 'no-reply@example.com'
$ExoPassFile = 'Path-to-encryped-password.txt'

# If doesn't exist then let's set some up!
If (!(Test-Path $ExoPassFile)) { 
    $GetPass = Read-Host -Prompt "Enter password:" -AsSecureString
    $GetPass | ConvertFrom-SecureString | Out-File $ExoPassFile 
}
# 
$ExoCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ExoLogin, (Get-Content $ExoPassFile | ConvertTo-SecureString)

$ExoSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/PowerShell/ -Credential $ExoCredentials -Authentication Basic -AllowRedirection

Import-PSSession $ExoSession
# For future functionality
Import-Module MsOnline
Connect-MsolService -Credential $ExoCredentials

# Set basic Alerting variables
$AlertTo = 'your_address@example.com'
$AlertWhat = 'New-InboxRule'
$AlertSMTP = 'smtp-relay.example.com'

# Add functionaly to pass argument in future
$SearchTime = Get-Date

# Default is 100 results returned. Not common to exceed but if shit hits the fan then or big userbase at least you get a better picture
$AuditLog = Search-UnifiedAuditLog -StartDate $SearchTime.AddMinutes(-15) -EndDate $SearchTime -Operations $AlertWhat -ResultSize 5000 | Select CreationDate, UserIds, Operations,AuditData,ResultIndex,ResultCount

foreach ($l in $AuditLog){
    # 
    $aData = $l.AuditData | ConvertFrom-Json
    $aTime = $aData.CreationTime
    $aUserId = $aData.UserId
    $aUserDetails = Get-MsolUser -UserPrincipalName $aUserId
    $aUserName = $aUserDetails.DisplayName
    $aParams = $aData.Parameters
    #
    if ($aParams -match 'SubjectOrBodyContainsWords'){
        foreach ($element in $aParams) {
        $elementValue = $element.Value
            if ($elementValue.Contains('hack')){

                $AlertSubject = "$AlertWhat - $aUserId!"
                # Using HTML so it can be expanded on in the future with pretty colors for idiots
                $AlertBody = "<h3>$aTime - $aUserId ($aUserName)</h3><p>Created new rule that contains: $elementValue</p></br><p style=font-weight:bold;>INVESTIGATE ASAP!!!</p>"

                Send-MailMessage -From $ExoLogin -To $AlertTo -Subject $AlertSubject -BodyAsHtml $AlertBody -SmtpServer $AlertSMTP
            }
        }
    }
} 

Remove-PSSession $ExoSession

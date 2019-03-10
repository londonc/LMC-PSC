#
$WebURL = 'https://www.yourhost/terms'
$FTPURL = 'ftp.yourhost.com'

# Depending on env you may want to use a more secure method of storing creds
$SmtpPass = ConvertTo-SecureString 'pass' -AsPlainText -Force
$SmtpUser = 'no-reply@yourhost.com'

$SmtpCreds = New-Object System.Management.Automation.PSCredential $SmtpUser, $SmtpPass

Function SendAlert($Alert){
    Send-MailMessage -SmtpServer smtp.office365.com -Port 587 -UseSSL -Credential $SmtpCreds -From $SmtpUser -To you@yourhost.com -Subject $Alert -BodyAsHtml $AlertBody 
}

Try {
    $ResponseGet = Invoke-WebRequest -Uri $WebURL -Method Get -UseBasicParsing -ErrorAction Stop
}
Catch {
    $ErrorMessage = $_.Exception.Message
    $AlertBody = "<h3>$ErrorMessage encountered when requesting <a href='$WebURL'>$WebURL</a>.</h3>"
    SendAlert -Alert "ALERT: $WebURL failing!"
    Break
}

$ResponseStatusCode = $ResponseGet.StatusCode

If ($ResponseStatusCode -eq 200){
    Write-Output "$WebURL is okay. "
} Else {
    $AlertBody = "<h3><a href='$WebURL'>$WebURL</a> responded but with $ResponseStatusCode instead of 200.</h3>"
    If (!($ResponseGet)){
        $AlertBody = $AlertBody + "See response below; <p>$ResponseGet</p>"
    }
    SendAlert -Alert "ALERT: $WebURL failing!"
}

$ResponseFTP = Test-NetConnection -ComputerName $FTPURL -Port 21

If ($ResponseFTP.TcpTestSucceeded -eq $true) {
    Write-Output "ftp://$FTPURL is okay. "
} Else {
    $AlertBody = "<h3>Error encountered when requesting <a href='ftp://$FTPURL'>$FTPURL</a>.</h3>"
    SendAlert -Alert "ALERT: $FTPURL failing!"
}

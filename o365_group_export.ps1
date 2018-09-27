$O365Creds = Get-Credential

$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/Powershell -Credential $O365Creds -AllowRedirection -Authentication basic

Import-PSSession $Session -AllowClobber

$Outputfile = Read-Host "Enter export path and filename, ie: C:\Users\londonc\Desktop\O365_groups.csv"


# Get all email distribution groups
$Groups = Get-DistributionGroup -ResultSize 5000

# Get all mail users, including contacts. 
$Users = Get-MailContact -ResultSize 5000

# Build list of all groups based on PrimarySmtpAddress since using GUID for later queries doesn't seem to work right.
$GroupColumn = New-Object Collections.generic.list[object]
ForEach ($i in $Groups) {
    $GroupColumn.Add("$($i.PrimarySmtpAddress)")
} 


# Declare to hold all the data
$Table = @()

# Iterate through every mail user
ForEach ($User in $Users) {

    $UserEmail = $User.PrimarySmtpAddress
    
    # Make object to hold each row of data to be exported
    $ObjRow = New-Object PSObject
    $ObjRow | Add-Member -MemberType NoteProperty -Name "Username" -Value $UserEmail

    # Query each group for it's members
    ForEach ($Group in $GroupColumn) {
        $GroupMembers = Get-DistributionGroupMember -Identity $Group

        # Find if user is in the group or not
        If($($GroupMembers.PrimarySmtpAddress) -contains "$UserEmail") {
            $IsMember = "true"
        }else{
            $IsMember = "false"
        }

        $ObjRow | Add-Member -MemberType NoteProperty -Name $Group -Value $IsMember

    }
    
    $Table += $ObjRow

    # Build CSV line by line. This way if something fails you still have saved results. 
    $Table | Export-Csv -Path $OutputFile -Append -NoTypeInformation
}

# Clean up 
Remove-PSSession $Session

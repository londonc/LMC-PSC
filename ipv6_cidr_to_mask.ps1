$InputFile = 'IPv6ListCIDR.txt'
$OutputFile = 'IPv6ListFull.txt'
$OutputTemp = ''


ForEach ($line in [System.IO.File]::ReadLines($InputFile)){

    $SubnetPosition = $line.IndexOf("/")
    $Network = $line.Substring(0, $SubnetPosition)
    $W = ''

    $IPObj = [System.Net.IPAddress] $Network

    #Could replace with :0000:0000RFC 5952
    $StrippedNetwork = $Network -replace '::',''
    $NetworkOctet = $StrippedNetwork.Split(':')

    #
    While ($NetworkOctet.Length -lt 8) {
        $NetworkOctet += '0'        
    }

    #
    
    $DoCount = 0
    Do {


     If($NetworkOctet[$DoCount].Length -lt 4){

        $NetworkOctet[$DoCount] = $NetworkOctet[$DoCount].PadLeft(4, '0')
     }

     # Pad left other, otherwise 0000000 = 0
     $W += [Convert]::ToString("0x$($NetworkOctet[$DoCount])", 2).PadLeft(16,'0')

     $DoCount ++


    } Until ($DoCount -eq 8)


    # Rebuild full network address
    [string]$IPv6Network = $NetworkOctet
    # Add colons back to address
    $IPv6Network = $IPv6Network -replace (' ',':')

    # Create Subnet Mask
    $SubnetCIDR = $line.Substring($SubnetPosition + 1)

    # There is always at least one 1 somewhere so may as well init with one. 
    $SubnetBin = '1'
    $SubnetBin = $SubnetBin.PadLeft($SubnetCIDR, '1')
    $SubnetBin = $SubnetBin.PadRight(128, '0')
    $BitNibble = [regex]::Matches($SubnetBin,'....') | Select Value


    $DoCount = 0
    $SubnetHex = ''
    Do {
        
        $DecimalNibble = [Convert]::ToInt32($BitNibble[$DoCount].Value, 2)
        $SubnetHex += [Convert]::ToString($DecimalNibble, 16)
        $DoCount ++
        
    } Until ($DoCount -eq 32)

    $IPv6SubnetMask = $SubnetHex -replace "(....(?!$))", '$1:'

    $OutputTemp += "$IPv6Network/$IPv6SubnetMask`r`n"


}

Out-File -FilePath $OutputFile -InputObject $OutputTemp

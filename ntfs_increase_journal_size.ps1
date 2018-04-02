# Powershell script to increase NTFS USN journal size so that it can easily be ran via GPO
# Author: London Crosby v0.5

# Set volume. Default is C:
$Volume = C:

#Set as MB. Default is 32MB.
$DesiredSize = 32

# Maths needed for conversion
$DesiredSizeInBytes = $DesiredSize * 1024 * 1024
$DesiredSizeInHex = "{0:x16}" -f $DesiredSizeInBytes

# Recommed setting Allocation Delta to around 20%
$AllocationDeltaInBytes = [math]::round($DesiredSizeInBytes * 0.2)
$AllocationDeltaInHex = [Convert]::ToString($AllocationDeltaInBytes, 16)


$GetUsnMaxSize = fsutil.exe usn queryjournal $Volume

foreach ($o in $GetUsnMaxSize){
   if ($o.StartsWith("Maximum Size")){
       # Split the output
       $oSetSize = $o -Split("0x")
       
       # Check if current value already matches desired size
       if ($oSetSize[1] -ne $DesiredSizeInHex) {
          # Set size otherwise
          fsutil usn createjournal m=$DesiredSizeInHex a=$AllocationDeltaInHex $Volume
       }

   }

} 

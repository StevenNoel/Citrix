 Param(
                [Parameter(Mandatory=$False)]
                [string[]]$PVSSites,
                [Parameter(Mandatory=$False)]
                [string]$LogDir
                #[ValidateSet($True,$False)]
                )


#Defines log path
$firstcomp = Get-Date
$filename = $firstcomp.month.ToString() + "-" + $firstcomp.day.ToString() + "-" + $firstcomp.year.ToString() + "-" + $firstcomp.hour.ToString() + "-" + $firstcomp.minute.ToString() + ".txt"
if (!($logdir))
    {
        $logdir = "\\ServerName\Share\Citrix\Logs\PVS\DeviceList"
    }
$outputloc = $LogDir + "\" + $filename

$hostname = hostname

Start-Transcript -Path $outputloc

asnp citrix*

if (!($PVSSites))
    {
        $PVSSites = 'SiteA-PVS1','SiteB-PVS1'
    }

Foreach ($PVSSite in $PVSSites)
    {
        Write-host "PVS Site:" *** $PVSSite ***
        Invoke-Command -ComputerName $PVSSite -ScriptBlock{
            Import-Module "C:\Program Files\Citrix\Provisioning Services Console\Citrix.PVS.SnapIn.dll"
            #Get-PvsDeviceInfo | Sort DeviceName | Where-Object {$_.DiskFileName -like "$image.name*"} | select Name
            $PVSCollections = Get-PvsCollection
                Foreach ($PVSCollection in $PVSCollections)
                    {
                        #Write-host $PVSCollection.collectionName
                        Get-PvsDeviceinfo -CollectionId $PVSCollection.collectionID | FT DeviceName,IP,DeviceMac,CollectionName,ServerName,Active,DiskFileName -AutoSize | Out-String -Width 4096
                    }
        }
    }

####################### Get Elapsed Time of Script ###########
$lastcomp = Get-date
$diff = ($lastcomp - $firstcomp)

Write-Host This Script took $diff.Minutes minutes and $diff.Seconds seconds to complete.
Write-Host "This Script Runs at 5:30AM from ($hostname)"

##############################################################

Stop-Transcript

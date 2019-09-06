 Param(
                [Parameter(Mandatory=$False)]
                [string[]]$PVSSites,
                [Parameter(Mandatory=$False)]
                [string]$LogDir,
                [Parameter(Mandatory=$False)]
                [switch]$PVS,
                [string]$Aplip,
                [string]$AESPath,
                [string]$SecurePassPath,
                [string]$AppLayeringModulePath
                #[ValidateSet($True,$False)]
                )

#Defines log path
$firstcomp = Get-Date
$filename = $firstcomp.month.ToString() + "-" + $firstcomp.day.ToString() + "-" + $firstcomp.year.ToString() + "-" + $firstcomp.hour.ToString() + "-" + $firstcomp.minute.ToString() + ".txt"

$outputloc = $LogDir + "\" + $aplip + "-" + $filename

$hostname = hostname

Start-Transcript -Path $outputloc

#Get Powerhsell module from https://www.powershellgallery.com/packages/ctxal-sdk/
Import-Module  $AppLayeringModulePath

#These two text files (AES and SecurePWD are created ahead of time via https://github.com/StevenNoel/Credentials
$AESKeyFilePath = $AESPath # location of the AESKey                
$SecurePwdFilePath = $SecurePassPath # location of the file that hosts the encrypted password                
$username = "administrator"
$AESKey = Get-Content -Path $AESKeyFilePath 
$pwdTxt = Get-Content -Path $SecurePwdFilePath
$securePass = $pwdTxt | ConvertTo-SecureString -Key $AESKey
$Credential = New-Object System.Management.Automation.PSCredential ($Username, $securePass)
$websession = Connect-alsession -aplip $aplip -Credential $Credential -Verbose


$images = Get-ALimage -websession $websession | Sort-Object Name
    foreach ($image in $images)
        {
            $imagedetail =  Get-ALimagedetail -websession $websession -id $image.id
            $osrev = $imagedetail.OsRev.Revisions.RevisionResult

            $myimage = New-Object -TypeName PSObject
            #Operating System
            $OS = [PSCustomObject]@{
                NAME = $imagedetail.OsRev.name
                ID = $imagedetail.OsRev.Revisions.RevisionResult.Id
                IMAGEID = $imagedetail.OSrev.ImageId
                RevNAME = $imagedetail.OsRev.Revisions.RevisionResult.Name
                Description = $imagedetail.OsRev.Revisions.RevisionResult.Description
                Status = $imagedetail.OsRev.Revisions.RevisionResult.Status
            }
            $myimage | Add-Member -MemberType NoteProperty -Name OSLayer -Value $OS

            #Platform
            $PL = [PSCustomObject]@{
                NAME = $imagedetail.PlatformLayer.name
                ID = $imagedetail.PlatformLayer.Revisions.RevisionResult.Id
                IMAGEID = $imagedetail.PlatformLayer.ImageId
                RevNAME = $imagedetail.PlatformLayer.Revisions.RevisionResult.Name
                Description = $imagedetail.PlatformLayer.Revisions.RevisionResult.Description
                Status = $imagedetail.PlatformLayer.Revisions.RevisionResult.Status
            }
            $myimage | Add-Member -MemberType NoteProperty -Name PlatformLayer -Value $PL

            #apps
            $apps = @()
            foreach ($app in $imagedetail.AppLayers.ApplicationLayerResult)
                {
                    $appobj = [PSCustomObject]@{
                    
                        NAME = $app.name
                        ID = $app.Revisions.RevisionResult.Id
                        ImageId = $app.ImageId
                        Priority = $app.Priority
                        RevNAME = $app.Revisions.RevisionResult.Name
                        Description = $app.Revisions.RevisionResult.Description
                        Status = $app.Revisions.RevisionResult.Status
                    }
                    
                    $apps += $appobj
    
                }
            $myimage | Add-Member -MemberType NoteProperty -Name AppLayer -Value $apps
        
        Write-host Image: ***** $image.Name ***** -ForegroundColor Green
        Write-host OS Layer -ForegroundColor Yellow
        $myimage.OSLayer | FT Name, RevNAME, ID, Description -AutoSize | Out-String -Width 4096
        Write-host Platform Layer -ForegroundColor Yellow
        $myimage.PlatformLayer | FT Name, RevName, ID, Description -AutoSize | Out-String -Width 4096
        Write-host App Layers -ForegroundColor Yellow
        $myimage.AppLayer | Sort Name | FT Name, RevName, ID, Description -AutoSize | Out-String -Width 4096

        Write-host "------------------------------------------------------"

       if ($PVS){
        Foreach ($PVSSite in $PVSSites)
            {
                Write-host "PVS Site:" $PVSSite "Using Image:" $image.name
                Invoke-Command -ComputerName $PVSSite -ScriptBlock{
                    Import-Module "C:\Program Files\Citrix\Provisioning Services Console\Citrix.PVS.SnapIn.dll"
                    #Write-host $args
                    $imagename = $args
                    Get-PvsDeviceInfo | Where-Object {$_.DiskFileName -like "*$imagename*"} | FT DeviceName,DiskFileName
                    
                } -ArgumentList $image.name
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

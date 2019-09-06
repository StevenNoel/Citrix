 Param(
                [Parameter(Mandatory=$False)]
                [string[]]$PVSSites,
                [Parameter(Mandatory=$False)]
                [string]$LogDir
                #[ValidateSet($True,$False)]
                )


#https://docs.citrix.com/en-us/provisioning/7-15/downloads/PvsSnapInCommands.pdf

#Defines log path
$firstcomp = Get-Date
$filename = $firstcomp.month.ToString() + "-" + $firstcomp.day.ToString() + "-" + $firstcomp.year.ToString() + "-" + $firstcomp.hour.ToString() + "-" + $firstcomp.minute.ToString() + ".txt"
if (!($logdir))
    {
        $logdir = "\\ServerName\Share\Citrix\Logs\PVS\PasswordReset"
    }
$outputloc = $LogDir + "\" + $filename

$hostname = hostname

Start-Transcript -Path $outputloc

asnp citrix*

#New Credentials
$NewCred = Get-Credential -Message "Enter 'NEW Hosting Connection' Credentials for PVS"
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($NewCred.Password)
$PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

if (!($PVSSites))
    {
        $PVSSites = 'SiteA-PVS1','SiteB-PVS1'
    }

Foreach ($PVSSite in $PVSSites)
    {
        Write-host "PVS Site: *** $PVSSite *** " -ForegroundColor Yellow
        Invoke-Command -ComputerName $PVSSite -ScriptBlock {
            Import-Module "C:\Program Files\Citrix\Provisioning Services Console\Citrix.PVS.SnapIn.dll"
            $PVSHostConnections = Get-PvsVirtualHostingPool -Verbose
            
            #Logging Existing Connections
            Write-host "Logging Existing PVS Hosting Connections:"
            $PVSHostConnections | FL -Property *
                
                Foreach ($PVSHostConnection in $PVSHostConnections)
                    {
                        Write-host "-"
                        Write-host "Working on" $PVSHostConnection.Name

                        If ($PVSHostConnection.Server -like "*http*")
                        {
                            $PVSHostConnection.server = $PVSHostConnection.server.Split("//")[2]
                        }
                            
                            
                        If (Test-Connection -ComputerName $PVSHostConnection.server -Count 1 -Quiet)
                        {
                            Write-host "PVS Hosting Connection Pingable:" $PVSHostConnection.Name
                            Try
                            {
                                Write-host "Trying to update credentials:" $PVSHostConnection.Name
                                $PVSHostConnection.UserName = $NewCred.UserName #$Args[0].Username
                                $PVSHostConnection.Password = $PlainPassword #$Args[1]
                                #$PVSHostConnection | Set-PvsVirtualHostingPool -Verbose
                                Write-host "Password Change Succeeded for:" $PVSHostConnection.Name -ForegroundColor Green
                                $PVSHostConnection | FT Name,Server,Username,VirtualHostingPoolID
                            }
                            Catch
                            {
                                Write-host "Unable to set new password for:" $PVSHostConnection.Name -ForegroundColor Red
                            }
                        }
                            
                        Else
                        {
                            Write-host "Can Remove Hosting Connection:" $PVSHostConnection.Name -ForegroundColor Red
                            Try
                            {
                                #Remove-PvsVirtualHostingPool -VirtualHostingPoolId $PVSHostConnection.VirtualHostingPoolId -verbose
                                Write-host "PVS Hosting Connection Removed for:" $PVSHostConnection.Name
                            }
                            Catch
                            {
                                Write-host "Unable to remove PVS Hosting Connection:" $PVSHostConnection.Name
                            }

                        }
                        
                        
   
                    } #End PVS Host Connection Foreach
        } -ArgumentList $NewCred,$PlainPassword #End Scriptblock
    } #End PVS Site Foreach

Remove-Variable NewCred -Verbose
Remove-Variable BSTR -Verbose
Remove-Variable PlainPassword -Verbose

####################### Get Elapsed Time of Script ###########
$lastcomp = Get-date
$diff = ($lastcomp - $firstcomp)

Write-Host This Script took $diff.Minutes minutes and $diff.Seconds seconds to complete.
Write-Host "This Script Runs at 5:30AM from ($hostname)"

##############################################################

Stop-Transcript

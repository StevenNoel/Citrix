#Region Settings
#Your License Server
$CitrixLicenseServer = "ctxlic01"

#Output location
$firstcomp = get-date
$filename = $firstcomp.month.ToString() + "-" + $firstcomp.day.ToString() + "-" + $firstcomp.year.ToString() + "-" + $firstcomp.hour.ToString() + "-" + $firstcomp.minute.ToString() + ".txt"
$outputloc = "\\fileserver\share\Licensing\" + $filename

$email=0

#Getting Total Number of licnenses and Inuse Counts
        ######*********************************################
function GetLicCount()
    {
        
        $left=0
        $count=0
        $inuse=0

        $LicenseData = Get-WmiObject -class "Citrix_GT_License_Pool" -namespace "ROOT\CitrixLicensing" -ComputerName $CitrixLicenseServer
        foreach ($license in $LicenseData)
            {
                #Adjust license edition if needed
                if ($license.PLD -match 'XDT_PLT_UD')
                    {
                        $count = $count + ($license.count - $license.Overdraft)
                        $inuse = $inuse + ($license.InUseCount) 
                    }
            }

        $left = $count - $inuse

        Write-Output "Total Licenses $count" | Out-File -Append $outputloc
        Write-Output "Inuse Licenses $Inuse" | Out-File -Append $outputloc
        Write-Output "Available Licenses $Left" | Out-File -Append $outputloc
        Write-Output "-" | Out-File $outputloc -Append

        #Adjust license value if needed
        if ($left -ilt '200')
            {
                Write-host Available Licenses Less than 200 "** Actual available: " $left
                $script:email=1 
            }
    }
###### End Get Lic Count Function################

####### Get License File in CSV format ################
function ExportList()
    {
        $d=0
        $term=0
        $t=0
        $c=0


        $udinfo = Invoke-Command -ComputerName $CitrixLicenseServer -ScriptBlock {
                #Change Install Path if needed
                cd "D:\Program Files (x86)\Citrix\Licensing\LS\"
                .\udadmin.exe -list -f XDT_PLT_UD
            }

        foreach ($info in $udinfo)
            {
                $enabled='null'
                $computer='null'
                $user,$lic,$date = $info.split(' ')
                
                    Try
                        {
                            $enabled = Get-ADUser $user
                        }
                    
                    Catch                          
                        {
                           $computer = Get-ADComputer $user
                        }
                    
                    #if OU has terminate or other keyword, change if necessary
                    if ($enabled.Enabled -match 'False' -and $enabled.distinguishedname -like '*terminate*')
                        {
                           $command = $user + "," + $date + "," + "TERMINATED"
                           Write-Output $command | Out-file -Append -FilePath $outputloc

                           ##### Actual Deletion using UDAdmin #####
                                $out = Invoke-Command -ComputerName $CitrixLicenseServer -ScriptBlock {
                                #Change Install Path if needed
                                cd "D:\Program Files (x86)\Citrix\Licensing\LS\"
                                .\udadmin.exe -f XDT_PLT_UD -user $($args[0]) -delete} -ArgumentList $user
                                $user + "," + $out | Out-File $outputloc -Append


                           $term++
                           $t++
                        }
                    
                    elseif ($enabled.Enabled -match 'False' -and $enabled.distinguishedname -notlike '*terminate*')
                        {
                           $command = $user + "," + $date + "," + "DISABLED"
                           Write-Output $command | Out-file -Append -FilePath $outputloc
                           $d++
                           $t++
                        }
                    elseif ($enabled.Enabled -match 'True')
                        {
                           $command = $user + "," + $date
                           Write-Output $command | Out-file -Append -FilePath $outputloc
                           $t++
                        }
                    elseif ($enabled -eq 'null' -and $computer -eq 'null')
                        {
                            $command = $user + "," + $date + "," + "USERNAME/Device NOT FOUND"
                           Write-Output $command | Out-file -Append -FilePath $outputloc
                           $t++
                        }
                    elseif ($computer -ne 'null' -or $user)
                        {
                           $command = $user + "," + $date + "," + "COMPUTER NAME"
                           Write-Output $command | Out-file -Append -FilePath $outputloc
                           $t++
                           $c++
                        } 
                
            }
       $command = "Total Terminated Accounts: " + $term
       Write-Output $command | Out-file -Append -FilePath $outputloc
       $command = "Total Disabled Accounts: " + $d
       Write-Output $command | Out-file -Append -FilePath $outputloc
       $command = "Total Computers: " + $c
       Write-Output $command | Out-file -Append -FilePath $outputloc
       $command = "Total Accounts: " + $t
       Write-Output $command | Out-file -Append -FilePath $outputloc
    }


######## End License file function #######################

GetLicCount
ExportList

#### Email #############################
Function Email
    {
        $results = (Get-Content -Path $outputloc) | Out-String
        $smtpserver = "smtp.domain.com"
        $msg = New-Object Net.Mail.MailMessage
        $smtp = New-Object net.Mail.SmtpClient($smtpserver)
        $msg.From = "Reporting@domain.com"
        $msg.To.Add("DL@domain.com")
        $msg.To.Add("DL2@domain.com")
        $msg.Subject = "**Citrix License Report**"
        $msg.body = "$results"
        #$msg.Attachments.Add($att)
        $smtp.Send($msg)
    }
#### END EMAIL  ############################

Write-Output "-" | Out-File $outputloc -Append
Write-Output "This Script Ran from ($env:hostname)" | Out-File $outputloc -Append

if ($email -eq '1')
    {
        Email
    }

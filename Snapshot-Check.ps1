# When deploying please update the variables below----
$SMTPServer = "MailRelay"
$Recipient = @("recipient@domain.com")
$Sender = "Alert@domain.com"
$vCenterServer = "vCenter.domain.local"
$Subject = "vCenter has snapshots hanging"
#-----------------------------------------------------

# Load the VMware PowerCLI module
Import-Module VMware.VimAutomation.Core

# Connect to vCenter Server
Connect-VIServer $vCenterServer

# Check if there are any snapshots on VMs
$snapshots = Get-VM | Get-Snapshot

# Check if any VMs require snapshot consolidation
$cons = Get-VM | ? {$_.Extensiondata.Runtime.ConsolidationNeeded}

# Send Email
# Create HTML Header
$body = @"
<!DOCTYPE HTML PUBLIC â€œ-//W3C//DTD HTML 4.01 Frameset//ENâ€ â€œhttp://www.w3.org/TR/html4/frameset.dtdâ€&gt;
<html><head><title>Snapshot Report</title><meta http-equiv=â€refreshâ€ content=â€120â€³ />
<style type=â€text/cssâ€>
<!â€“
body {
	font-family: 'Helvetica Neue', Arial, sans-serif;
	font-size: 14px;
    line-height: 1.42857143;
    color: #333;
}
p {
	font-family: 'Helvetica Neue', Arial, sans-serif;
	font-size: 14px;
    line-height: 1.42857143;
    color: #333;
	margin-left: 20px;
}
â€“>
</style>
</head>
<body>
<p>
"@

# Only construct and send an email if there are any results found.
if ($snapshots -Or $cons) {
    if ($snapshots) {

    # Construct a table of information about any snapshots.
        $all_snaps_info =@()
        foreach ($snapshot in $snapshots){
			$vm = $snapshot.VM
				$single_snap_info = New-Object PSObject
				$single_snap_info | Add-Member -Name "VMName" -Value $($snapshot.VM).Name -MemberType NoteProperty
				$single_snap_info | Add-Member -Name "SnapshotName" -Value $snapshot.Name -MemberType NoteProperty
				$single_snap_info | Add-Member -Name "SnapSizeInMB" -Value $("{0:N2}" -f ($snapshot.SizeMB)) -MemberType NoteProperty
				$snapdatastores = $snapshot.VM | Get-Datastore
				$single_snap_info | Add-Member -Name "VMDatastore" -Value "$snapdatastores" -MemberType NoteProperty
				$snapdatastoresizes = Foreach ($snapstore in $snapdatastores) {
					[System.Math]::Round($snapstore.FreeSpaceGB) 
					}
				$single_snap_info | Add-Member -Name "VMDatastoreSpaceGB" -Value "$snapdatastoresizes" -MemberType NoteProperty
				$all_snaps_info += $single_snap_info
        }
        $body += "<p>$vCenterServer Snapshots Hanging:</p><p>"
        $body += ($all_snaps_info | ConvertTo-HTML -Fragment)
    }
    # Construct a table of information about any VMs requiring consolidation
    if ($cons) {
        Write-Host "generating cons data"
        $all_cons_info =@()
        foreach ($con in $cons){
            $single_con_info = New-Object PSObject
            $single_con_info | Add-Member -Name "VMName" -Value $con.Name -MemberType NoteProperty
			$consdatastores = $con | Get-Datastore
            $single_con_info | Add-Member -Name "VMDatastore" -Value "$consdatastores" -MemberType NoteProperty
			$consdatastoresizes = Foreach ($consstore in $consdatastores) {
				[System.Math]::Round($consstore.FreeSpaceGB) 
				}
            $single_con_info | Add-Member -Name "VMDatastoreSpaceGB" -Value "$consdatastoresizes" -MemberType NoteProperty
            $all_cons_info += $single_con_info
        }
        $body += "</p><p>$vCenterServer Consolidations Needed:</p><p>"
        $body += ($all_cons_info | ConvertTo-HTML -Fragment)
    }

    # Export the email body
    $Body | Out-File C:\Scripts\Output.htm

    # Send the email
	Send-MailMessage -To $Recipient -From $Sender -Subject $Subject -BodyAsHtml -Body $Body -SmtpServer $SMTPServer
}

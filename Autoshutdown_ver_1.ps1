<#	===============================================================================================================
	 Created on:   	03/4/2019
	 Created by:   	Agustin.Lacorazza - alacorazza@primary.com.ar
	 Organization: 	Primary technology
	 Filename:     	Shutdown_Vcenter
	--------------------------------------------------------------------------------------------------
	 Description:  Script to conect to the Vcenter server and start to shuting down all the Guest & listed hosts
	==============================================================================================================#>

<#
MIX Variables to change
#>

$credientialfile =  ""    # ---> Vcenter Credentials xml
$logfolder = ""               # ---> Log folder rute
$VirtualCenterServer = ""   # ---> Vcenter direction
$NAS_credentials = ""  # ---> Nas Cred$Bashscriptsfile = "C:\dev\bash\"        # ---> Bash Scripts to run Plink


<#
Hosts Maipu Information per Cluster  | Need to change below for each physical host
#>

$hostinfraestructura = "
$hostspmycl01 = "","","",""
$hostspmyclprf = ""
$hostsmanagement = ""

<#
V-Center Information & Credentials  | Do not change anything
#>


New-Item -ItemType Directory -Path "$logfolder\$((Get-Date).ToString('yyyy-MM-dd'))"
$Logfile = "$logfolder\$((Get-Date).ToString('yyyy-MM-dd'))\Autoshutdown.log"

Get-VICredentialStoreItem -File $credientialfile  | %{
Connect-VIServer -Server $_.host -User $_.User -Password $_.Password
}

Function LogWrite
{
   Param ([string]$logstring)

   Add-content $Logfile -value $logstring
}

<#
VM Listed per Cluster | Connect to each host and list the vms in a cluster
#>

$Infraestructura = Get-Cluster "Infraestructura" | Get-vm  | select name
$PMY01 = Get-Cluster "PMY-CL-01" | Get-vm  | select name
#$PMYPERF = Get-Cluster "PMY-CL-PERF" | Get-vm  | select name
$Management = Get-Cluster "Management" | Get-vm  | select name

<#
Start Functions Process | One function is created to shutdown each Cluster & Function to call Plink stablish SSH run Shutdown NAS Linux
#>
function Invoke-Plink {
    param (
        [string] $ipa,
        [string] $cmd,
        [string] $usr,
        [string] $pwd,
        [string] $m
    )

    if ($cmd) {
        echo y |  C:\dev\Tools\plink.exe $usr@$ipa -pw $pwd $cmd
    } else {
        echo y |  C:\dev\Tools\plink.exe $usr@$ipa -pw $pwd -m $m
    }
	}

function cluster_Infraestructura
{
    Foreach ($esxhost in $hostinfraestructura)
    {
    $currentesxhost = get-vmhost $esxhost
    LogWrite “Processing $currentesxhost”
    #loop through each vm on host
    Foreach ($VM in ($currentesxhost | Get-VM | where { $_.PowerState -eq “PoweredOn” }))
    {
    LogWrite “====================================================================”
    LogWrite “Processing $vm”

    if ($Infraestructura -contains $vm)
    {
    LogWrite “ $vm – Shutdown”
    }
    else
    {
    LogWrite “Checking VMware Tools….”
    $vminfo = get-view -Id $vm.ID
    # If we have VMware tools installed
    if ($vminfo.config.Tools.ToolsVersion -eq 0)
    {
    LogWrite “$vm doesn’t have vmware tools installed, hard power this one”
    # Hard Power Off
    Stop-VM $vm -confirm:$false
    }
    else
    {
    LogWrite “I will attempt to shutdown $vm”
    # Power off
    $vmshutdown = $vm | shutdown-VMGuest -Confirm:$false
    }
    }
    LogWrite “====================================================================”
    }
        LogWrite “Initiating host shutdown in 30 seconds”
        sleep 30
        #look for other vm’s still powered on.
        Foreach ($VM in ($currentesxhost | Get-VM | where { $_.PowerState -eq “PoweredOn” }))
        {
            LogWrite “====================================================================”
            LogWrite “Processing $vm”
            Stop-VM $vm -confirm:$false
            LogWrite “====================================================================”
        }
        #Shut down the host
        Sleep 20
        Set-VMhost -VMhost $currentesxHost -State Maintenance
        Sleep 15
        $currentesxhost | Foreach {Get-View $_.ID} | Foreach {$_.ShutdownHost_Task($TRUE)}
    }
    LogWrite “Shutdown Cluster Infraestructura Complete”

}

function cluster_PMY01
{
    Foreach ($esxhost in $hostspmycl01)
    {
    $currentesxhost = get-vmhost $esxhost
    LogWrite “Processing $currentesxhost”
    #loop through each vm on host
    Foreach ($VM in ($currentesxhost | Get-VM | where { $_.PowerState -eq “PoweredOn” }))
    {
    LogWrite “====================================================================”
    LogWrite “Processing $vm”

    if ($PMY01 -contains $vm)
    {
    LogWrite “ $vm – shutdown”
    }
    else
    {
    LogWrite “Checking VMware Tools….”
    $vminfo = get-view -Id $vm.ID
    # If we have VMware tools installed
    if ($vminfo.config.Tools.ToolsVersion -eq 0)
    {
    LogWrite “$vm doesn’t have vmware tools installed, hard power this one”
    # Hard Power Off
    Stop-VM $vm -confirm:$false
    }
    else
    {
    LogWrite “I will attempt to shutdown $vm”
    # Power off
    $vmshutdown = $vm | shutdown-VMGuest -Confirm:$false
    }
    }
    LogWrite “====================================================================”
    }
        LogWrite “Initiating host shutdown in 30 seconds”
        sleep 30
        #look for other vm’s still powered on.
        Foreach ($VM in ($currentesxhost | Get-VM | where { $_.PowerState -eq “PoweredOn” }))
        {
            LogWrite “====================================================================”
            LogWrite “Processing $vm”
            Stop-VM $vm -confirm:$false
            LogWrite “====================================================================”
        }
        #Shut down the host
        Sleep 20
        Set-VMhost -VMhost $currentesxHost -State Maintenance
        Sleep 15
        $currentesxhost | Foreach {Get-View $_.ID} | Foreach {$_.ShutdownHost_Task($TRUE)}
    }
    LogWrite “Shutdown Complete”

}

function cluster_PMYPERF
{
    Foreach ($esxhost in $hostspmyclprf)
    {
    $currentesxhost = get-vmhost $esxhost
    LogWrite “Processing $currentesxhost”
    #loop through each vm on host
    Foreach ($VM in ($currentesxhost | Get-VM | where { $_.PowerState -eq “PoweredOn” }))
    {
    LogWrite “====================================================================”
    LogWrite “Processing $vm”

    if ($PMYPERF -contains $vm)
    {
    LogWrite “ $vm – Shutdown”
    }
    else
    {
    LogWrite “Checking VMware Tools….”
    $vminfo = get-view -Id $vm.ID
    # If we have VMware tools installed
    if ($vminfo.config.Tools.ToolsVersion -eq 0)
    {
    LogWrite “$vm doesn’t have vmware tools installed, hard power this one”
    # Hard Power Off
    Stop-VM $vm -confirm:$false
    }
    else
    {
    LogWrite “I will attempt to shutdown $vm”
    # Power off
    $vmshutdown = $vm | shutdown-VMGuest -Confirm:$false
    }
    }
    LogWrite “====================================================================”
    }
        LogWrite “Initiating host shutdown in 30 seconds”
        sleep 30
        #look for other vm’s still powered on.
        Foreach ($VM in ($currentesxhost | Get-VM | where { $_.PowerState -eq “PoweredOn” }))
        {
            LogWrite “====================================================================”
            LogWrite “Processing $vm”
            Stop-VM $vm -confirm:$false
            LogWrite “====================================================================”
        }
        #Shut down the host
        Sleep 20
        Set-VMhost -VMhost $currentesxHost -State Maintenance
        Sleep 15
        $currentesxhost | Foreach {Get-View $_.ID} | Foreach {$_.ShutdownHost_Task($TRUE)}
    }
    LogWrite “Shutdown Complete”

}

function Shutdown_NAS
 {

	$Systems = Import-Csv $NAS_credentials

	foreach ($NAS in $Systems) {

        LogWrite "Shuting Down" $NAS.system
	    $passwd = $NAS.password -replace {"$","`$"}
        $ssh1  = Invoke-Plink -ipa $NAS.IP -usr $NAS.user -pw $passwd  shutdown
        #LogWrite " ShutingDown Nas"
        $Output1 += $ssh1
        $temp = $logfolder + "\Log_NAS.txt"
        LogWrite $Output1 #| Out-File $temp
        }

       }

function cluster_Management
{
    LogWrite "shuting down $Management full host "
    Stop-VMHost $hostsmanagement -confirm -RunAsync -Force

}



<#
End Functions Process
#>




cluster_Infraestructura
cluster_PMY01
Shutdown_NAS
cluster_Management

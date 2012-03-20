
Add-Type -AssemblyName System.ServiceProcess
Add-Type -AssemblyName System.Messaging

function Get-MSMQMessageQueue
{
    <#
    .SYNOPSIS
    Gets the MSMQ message queue by the given name, or $null if one doesn't exist.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the queue to get.
        $Name,
        
        [Switch]
        # Is the queue private?
        $Private
    )
   
    $privateArg = @{ Private = $Private }
    
    if( Test-MSMQMessageQueue -Name $Name @privateArg )
    {
        $path = Get-MSMQMessageQueuePath -Name $Name @privateArg 
        New-Object -TypeName Messaging.MessageQueue -ArgumentList ($path)
    }
    else
    {
        return $null
    }
}

function Get-MSMQMessageQueuePath
{
    <#
    .SYNOPSIS
    Gets the path to an MSMQ message queue.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The queue's name.  
        $Name,
        
        [Switch]
        # Is the queue private?
        $Private
    )
    
    $path = ".\$Name"
    if( $Private )
    {
        $path = ".\private`$\$Name"
    }
    return $path
}

function Grant-MSMQMessageQueuePermissions
{
    <#
    .SYNOPSIS
    Grants a user permissions on an MSMQ message queue.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The queue name.
        $Name,
        
        [Switch]
        # Is the queue private?
        $Private,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The user to grant permissions to.
        $Username,
        
        [Parameter(Mandatory=$true)]
        [Messaging.MessageQueueAccessRights[]]
        # The rights to grant the user.
        $AccessRights
    )
    
    $queueArgs = @{ Name = $Name ; Private = $Private }
    $queue = Get-MSMQMessageQueue @queueArgs
    if( -not $queue )
    {
        throw "Queue '$Name' doesn't exist."
    }
    
    if( $pscmdlet.ShouldProcess( $Name, "grant '$AccessRights' to '$User'" ) )
    {
        Write-Host "Granting user '$Username' '$AccessRights' permissions to MSMQ message queue '$Name'."
        $queue.SetPermissions( $Username, $AccessRights )
    }
}

function Install-MSMQ
{
    <#
    .SYNOPSIS
    Installs Microsoft's Message Queueing system.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Switch]
        # Enable HTTP Support
        $HttpSupport,
        
        [Switch]
        # Enable Active Directory Integrations
        $ActiveDirectoryIntegration,
        
        [Switch]
        # Will MSMQ be participating in external, distributed transactions? I.e. will it be sending messages to queues on other machines?
        $DTC
    )
    
    $optionalArgs = @{ }
    if( $HttpSupport )
    {
        $optionalArgs.HttpSupport = $true
    }
    
    if( $ActiveDirectoryIntegration )
    {
        $optionalArgs.ActiveDirectoryIntegration = $true
    }
    
    Install-WindowsFeatureMsmq @optionalArgs
    
    if( $DTC )
    {
        Set-Service -Name MSDTC -StartupType Automatic
        Start-Service -Name MSDTC
        $svc = Get-Service -Name MSDTC
        $svc.WaitForStatus( [ServiceProcess.ServiceControllerStatus]::Running )
    }
}

function Install-MSMQMessageQueue
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the queue.
        $Name,
        
        [Switch]
        # Is the queue private?
        $Private,
        
        [Switch]
        # Is the queue transactional?
        $Transactional
    )
    
    $queueArgs = @{ Name = $Name ; Private = $Private }
    $path = Get-MSMQMessageQueuePath @queueArgs 
    
    $logMessage = "MSMQ message queue '$Name'."
    if( Test-MSMQMessageQueue @queueArgs )
    {
        Write-Host "Re-creating $logMessage"
        Remove-MSMQMessageQueue @queueArgs
    }
    else
    {
        Write-Host "Creating $logMessage"
    }
    
    # If you remove a queue, sometimes you can't immediately re-create it.  So, we keep trying until we can.
    do
    {
        try
        {
            # Capture the return object, otherwise it gets sent down the pipeline and causes an error
            $queue = [Messaging.MessageQueue]::Create( $path, $Transactional )
            break
        }
        catch { }
        Start-Sleep -Milliseconds 100
    }
    while( $true )
    
    while( -not (Test-MSMQMessageQueue @queueArgs) )
    {
        Start-Sleep -Milliseconds 100
    }
}

function Remove-MSMQMessageQueue
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the queue to remove.
        $Name,
        
        [Switch]
        # Is this a private queue?
        $Private
    )
    
    $commonArgs = @{ 'Name' = $Name ; 'Private' = $Private }
    
    if( -not (Test-MSMQMessageQueue @commonArgs) )
    {
        return
    }
    
    if( $pscmdlet.ShouldProcess( "MSMQ Message Queue $Name", "remove" ) )
    {
        try
        {
            [Messaging.MessageQueue]::Delete( (Get-MSMQMessageQueuePath @commonArgs) )
        }
        catch
        {
            Write-Error $_
            return
        }
        while( Test-MSMQMessageQueue @commonArgs )
        {
            Start-Sleep -Milliseconds 100
        }
    }
}

function Test-MSMQMessageQueue
{
    <#
    .SYNOPSIS
    Tests if an MSMQ message queue exists.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The queue name.
        $Name,
        
        [Switch]
        # Is the queue private?
        $Private
    )
    
    $queueArgs = @{ Name = $Name ; Private = $Private }
    $path = Get-MSMQMessageQueuePath @queueArgs 
    return ( [Messaging.MessageQueue]::Exists( $path ) )
}


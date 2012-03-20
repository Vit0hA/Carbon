
$singleFeature = 'Telnet-Client'
$multipleFeatures = @( $singleFeature, 'TFTP-Client' )

if( (Get-Command servermanagercmd.exe -ErrorAction SilentlyContinue) )
{
}
elseif( (Get-WmiObject -Class Win32_OptionalFeature -ErrorAction SilentlyContinue) )
{
    $singleFeature = 'TelnetClient'
    $multipleFeatures = @( $singleFeature, 'TFTP' )
}
else
{
    Write-Error "Tests for Install-WindowsFeatures not supported on this operating system."
}


function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon) -Force
    Install-WindowsFeatures -Features $multipleFeatures
}

function Teardown
{
    Uninstall-WindowsFeatures -Features $multipleFeatures
    Remove-Module Carbon
}

function Test-ShouldUninstallFeatures
{
    Assert-True (Test-WindowsFeature -Name $singleFeature)
    Uninstall-WindowsFeatures -Features $singleFeature
    Assert-False (Test-WindowsFeature -Name $singleFeature)
}

function Test-ShouldUninstallMultipleFeatures
{
    Assert-True (Test-WindowsFeature -Name $multipleFeatures[0])
    Assert-True (Test-WindowsFeature -Name $multipleFeatures[1])
    Uninstall-WindowsFeatures -Features $multipleFeatures
    Assert-False (Test-WindowsFeature -Name $multipleFeatures[0])
    Assert-False (Test-WindowsFeature -Name $multipleFeatures[1])
}

function Test-ShouldSupportWhatIf
{
    Assert-True (Test-WindowsFeature -Name $singleFeature)
    Uninstall-WindowsFeatures -Features $singleFeature -WhatIf
    Assert-True (Test-WindowsFeature -Name $singleFeature)
}

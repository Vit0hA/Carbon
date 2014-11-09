# Copyright 2012 Aaron Jensen
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

if( $PSVersionTable.PSVersion -gt [Version]'2.0' -and -not (Get-Module 'ServerManager') -and (Get-WmiObject -Class Win32_OptionalFeature -ErrorAction SilentlyContinue) )
{
    $singleFeature = 'TelnetClient'
    $multipleFeatures = @( $singleFeature, 'TFTP' )

    function Start-TestFixture
    {
        & (Join-Path -Path $PSScriptRoot -ChildPath '..\Import-CarbonForTest.ps1' -Resolve)
    }

    function Start-Test
    {
        Install-WindowsFeature -Name $multipleFeatures
    }

    function Stop-Test
    {
        Uninstall-WindowsFeature -Name $multipleFeatures
    }

    function Test-ShouldUninstallFeatures
    {
        Assert-True (Test-WindowsFeature -Name $singleFeature -Installed)
        Uninstall-WindowsFeature -Name $singleFeature
        Assert-False (Test-WindowsFeature -Name $singleFeature -Installed)
    }

    function Test-ShouldUninstallMultipleFeatures
    {
        Assert-True (Test-WindowsFeature -Name $multipleFeatures[0] -Installed)
        Assert-True (Test-WindowsFeature -Name $multipleFeatures[1] -Installed)
        Uninstall-WindowsFeature -Name $multipleFeatures
        Assert-False (Test-WindowsFeature -Name $multipleFeatures[0] -Installed)
        Assert-False (Test-WindowsFeature -Name $multipleFeatures[1] -Installed)
    }

    function Test-ShouldSupportWhatIf
    {
        Assert-True (Test-WindowsFeature -Name $singleFeature -Installed)
        Uninstall-WindowsFeature -Name $singleFeature -WhatIf
        Assert-True (Test-WindowsFeature -Name $singleFeature -Installed)
    }

}
else
{
    Write-Warning "Tests for Uninstall-WindowsFeature not supported on this operating system."
}

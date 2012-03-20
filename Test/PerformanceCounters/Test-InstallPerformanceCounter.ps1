
$CategoryName = 'Carbon-PerformanceCounters'

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force
}

function TearDown
{
    Uninstall-PerformanceCounterCategory -CategoryName $CategoryName
    Assert-False (Test-PerformanceCounterCategory -CategoryName $CategoryName) 'Performance counter category not uninstalled.'
}

function Test-ShouldInstallNewPerformanceCounterWithNewCategory
{
    $name = 'Test Counter'
    $description = 'Counter used to test that Carbon installation function works.'
    $type = 'NumberOfItems32'
    
    Install-PerformanceCounter -CategoryName $CategoryName -Name $name -Description $description -Type $type
    Assert-True (Test-PerformanceCounterCategory -CategoryName $CategoryName) 'Category not auto-created.'
    Assert-True (Test-PerformanceCounter -CategoryName $CategoryName -Name $name)
    $counters = Get-PerformanceCounters -CategoryName $CategoryName
    Assert-Equal 1 $counters.Length
    Assert-Counter $counters[0] $name $description $type
}

function Test-ShouldPreserveExistingCountersWhenInstallingNewCounter
{
    $name = 'Test Counter'
    $description = 'Counter used to test that Carbon installation function works.'
    $type = 'NumberOfItems32'
    Install-PerformanceCounter -CategoryName $CategoryName -Name $name -Description $description -Type $type
    
    $name2 = 'Test Counter 2'
    $description2 = 'Second counter used to test that Carbon installation function works.'
    $type2 = 'NumberOfItems64'
    Install-PerformanceCounter -CategoryName $CategoryName -Name $name2 -Description $description2 -Type $type2
    
    $counters = Get-PerformanceCounters -CategoryName $CategoryName
    Assert-Equal 2 $counters.Length
    Assert-Counter $counters[0] $name $description $type
    Assert-Counter $counters[1] $name2 $description2 $type2   
}

function Test-ShouldSupportWhatIf
{
    $name = 'Test Counter'
    $description = 'Counter used to test that Carbon installation function works.'
    $type = 'NumberOfItems32'
    Install-PerformanceCounter -CategoryName $CategoryName -Name $name -Description $description -Type $type -WhatIf
    Assert-False (Test-PerformanceCounterCategory -Categoryname $CategoryName)
    Assert-False (Test-PerformanceCounter -CategoryName $CategoryName -Name $name)    
}

function Test-ShouldReinstallExistingPerformanceCounter
{
    $name = 'Test Counter'
    $description = 'Counter used to test that Carbon installation function works.'
    $type = 'NumberOfItems32'
    Install-PerformanceCounter -CategoryName $CategoryName -Name $name -Description $description -Type $type
    
    $newDescription = '[New] ' + $description
    $newType = 'NumberOfItems64'
    Install-PerformanceCounter -CategoryName $CategoryName -Name $name -Description $newDescription -Type $newType
    $counters = Get-PerformanceCounters -CategoryName $CategoryName
    Assert-Counter $counters[0] $name $newDescription $newType
}

function Assert-Counter($Counter, $Name, $Description, $Type)
{
    Assert-Equal $Name $Counter.CounterName
    Assert-Equal $Description $Counter.CounterHelp
    Assert-Equal $Type $Counter.CounterType

}
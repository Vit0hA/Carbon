﻿<#
.SYNOPSIS
Createa a Carbon NuGet package and pushes it to nuget.org.
#>
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
[CmdletBinding()]
param(
)

Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Carbon\Import-Carbon.ps1' -Resolve)

$tempDir = New-TempDir
$libDir = Join-Path -Path $tempDir -ChildPath 'lib'
$contentDir = Join-Path -Path $tempDir -ChildPath 'content'
$toolsDir = Join-Path -Path $tempDir -ChildPath 'tools'

foreach( $contentSource in @( 'Carbon', 'Website', 'Examples' ) )
{
    Copy-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath $contentSource)  `
              -Destination (Join-Path -Path $contentDir -ChildPath $contentSource) `
              -Recurse
}

foreach( $file in @( '*.txt', 'Carbon.nuspec' ) )
{
    Copy-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath $file) `
              -Destination $tempDir
}

Push-Location $tempDir
try
{
    $nugetPath = Join-Path -Path $PSScriptRoot -ChildPath 'Tools\NuGet-2.8\NuGet.exe' -Resolve
    & $nugetPath pack '.\Carbon.nuspec' -BasePath '.'

    & $nugetPath push (Join-Path -Path $tempDir -ChildPath 'Carbon*.nupkg')
}
finally
{
    Pop-Location
    Remove-Item -Recurse $tempDir
}
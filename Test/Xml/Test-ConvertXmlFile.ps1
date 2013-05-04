
$tempDir = $null
$xmlFilePath = $null
$xdtFilePath = $null
$resultFilePath = $null

function Setup()
{
    & (Join-Path $TestDir ..\..\Carbon\Import-Carbon.ps1 -Resolve)
	
    $tempDir = New-TempDirectory -Prefix 'Carbon-Test-ConvertXmlFile'
	# create a valid base file
	# create test files
	
    $xmlFilePath = Join-Path $tempDir 'in.xml'
    $xdtFilePath = Join-Path $tempDir 'xdt.xml'
    $resultFilePath = Join-Path $tempDir 'out.xml'
}

function TearDown()
{
    if( (Test-Path -Path $tempDir -PathType Container ) )
    {
        #Remove-Item $tempDir -Recurse
    }
        
	Remove-Module Carbon
}

function Test-ShouldConvertXmlFileUsingFilesAsInputs
{
	@'
<?xml version="1.0"?>
<configuration>
	<connectionStrings>
	</connectionStrings>
</configuration>
'@ > $xmlFilePath
	
	
	@'
<?xml version="1.0"?>
<configuration xmlns:xdt="http://schemas.microsoft.com/XML-Document-Transform">
	<connectionStrings>
		<add name="MyDB" connectionString="some value" xdt:Transform="Insert" />
	</connectionStrings>
</configuration>
'@ > $xdtFilePath
	
	# act
	Convert-XmlFile -Path $xmlFilePath -XdtPath $xdtFilePath -Destination $resultFilePath

    Assert-FileExists $resultFilePath
	
	# assert
	$newContext = Get-Content $resultFilePath
	Assert-True ($newContext -match '<add name="MyDB" connectionString="some value"/>')
}

function Test-ShouldAllowUsersToLoadCustomTransforms
{
    $carbonTestAssemblyPath = Join-Path $TestDir ..\..\Source\Test\bin\Debug\Carbon.Test.dll -Resolve
    Add-Type -Path $carbonTestAssemblyPath

	@'
<?xml version="1.0"?>
<configuration>
    <connectionStrings>
        <add name="PreexistingDB" />
    </connectionStrings>

    <one>
        <two>
            <two.two />
        </two>
        <three />
    </one>
</configuration>
'@ > $xmlFilePath
	
	@'
<?xml version="1.0"?>
<configuration xmlns:xdt="http://schemas.microsoft.com/XML-Document-Transform">
    <xdt:Import path="{0}" namespace="Carbon.Test.Xdt"/>
	
	<connectionStrings xdt:Transform="Merge" >
		<add name="MyDB" xdt:Locator="Match(name)" xdt:Transform="Remove" />
		<add name="MyDB" connectionString="some value" xdt:Transform="Insert" />
	</connectionStrings>
	
	<one xdt:Transform="Merge">
		<two xdt:Transform="Merge">
		</two>
	</one>
	
</configuration>
'@ -f $carbonTestAssemblyPath > $xdtFilePath
	
	# act
	Convert-XmlFile -Path $xmlFilePath -XdtPath $xdtFilePath -Destination $resultFilePath 
	
	# assert
	$newContext = (Get-Content $resultFilePath) -join "`n"
	
	Assert-True ($newContext -match '<add name="MyDB" connectionString="some value"/>')
	Assert-True ($newContext -match '<add name="PreexistingDB" />')
	Assert-True ($newContext -match '<two\.two/>')
	Assert-True ($newContext -match '<three/>')
}

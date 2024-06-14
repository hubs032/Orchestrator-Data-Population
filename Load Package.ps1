<#
.DESCRIPTION
    This script is intented to upload a package (.nupkg file) to the Orchestrator over its API
.NOTES
    Tested in version 2019.10
    Script created on 2020/6 by Masire FOFANA (masire.fofana@natixis.com)
#>

<# Set variables below #>

# URL of the Orchestrator
$targetURL = 'https://cloud.uipath.com/aaronhubbartTAMsandbox/'

# Name of the tenant
$targetTenant = 'Sandbox'

# Orchestrator local user name (needs package creation right)
$targetUsername = 'aaron.hubbart@uipath.com'

# Orchestrator local user password
$targetPassword = ''

# Full path of package to upload (needs to be an .nupkg file)
$packageLocation = 'C:\Users\aaron.hubbart\OneDrive - UiPath\Desktop\1password.login.1.0.1.nupkg'

<# Script below #>
$headers = @{
    'Accept' = 'application/json'
}
$loginModel = @{
    'tenancyName' = $targetTenant
    'usernameOrEmailAddress' = $targetUsername
    'password' = $targetPassword
}
$uri = $targetURL + 'api/Account/Authenticate'

$result = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $loginModel
if ($result.success) {
    $bearer = $result.result
    $headers.Add('Authorization', "Bearer $bearer")
    
    $fileBytes = [System.IO.File]::ReadAllBytes($packageLocation);
    $fileEnc = [System.Text.Encoding]::GetEncoding('ISO-8859-1').GetString($fileBytes);
    $boundary = [System.Guid]::NewGuid().ToString(); 
    $LF = "`r`n";

    $bodyLines = ( 
        "--$boundary",
        "Content-Disposition: form-data; name=`"file`"; filename=`"$(Split-Path $packageLocation -Leaf)`"",
        "Content-Type: application/octet-stream$LF",
        $fileEnc,
        "--$boundary--$LF" 
    ) -join $LF
    
    $headers.Add('Content-Type', "multipart/form-data; boundary=`"$boundary`"")

    $uri = $targetURL + 'odata/Processes/UiPath.Server.Configuration.OData.UploadPackage'

    $uploaded = $false
    try {
        $result = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $bodyLines
        $uploaded = $true
    } catch {
        Write-Host "An error occured: $_"
    }

    if ($uploaded) {
        Write-Host "Yay!"
    } else {
        Write-Host "Sorry, not working..."
    }
}
else{
write-host "Couldn't authenticate"
}
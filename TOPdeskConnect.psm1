Function Connect-TOPdeskAPI {
    param(
        [parameter(mandatory)]
        $TopdeskUrl,
        [parameter(mandatory)]
        $TdLoginName,
        [parameter(mandatory)]
        $TdSecret
    )
    $Script:topdeskAuthenticationHeader = @{'Authorization' = "Basic $([Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("$($TdLoginName):$($TdSecret)")))"}
    $Script:topdeskUrl = "$TopdeskUrl"
    $Script:topdeskAuthenticated = $false

    Write-Output "Authenticating to TOPdesk API"

    $testApi = Invoke-RestMethod -Uri "$TopdeskUrl/tas/api/version" -ContentType "application/json" -Method GET -Headers $topdeskAuthenticationHeader

    if ($testApi){
        $Script:topdeskAuthenticated = $true
        Write-Output "Successfully authenticated"
        return ""
    }
    Write-Output "Authentication was unsuccessful"
}
function Find-TOPdeskConnection {
    if (!$topdeskAuthenticated){
        Write-Warning "Topdesk API is not authenticated, you need to run Connect-TOPdeskAPI and make sure you put in the correct credentials!"
        return $false
    }
    return $true
}

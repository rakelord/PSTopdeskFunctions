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
}
function Find-TOPdeskConnection {
    if (!$topdeskAuthenticated){
        Write-Warning "Topdesk API is not authenticated, you need to run Connect-TOPdeskAPI and make sure you put in the correct credentials!"
        return $false
    }
    return $true
}
function Get-TdAssetTemplates {
    if (Find-TOPdeskConnection) {
        return (Invoke-RestMethod -Uri "$topdeskUrl/tas/api/assetmgmt/templates" -ContentType "application/json" -Method GET -Headers $topdeskAuthenticationHeader).dataSet
    }
}
function Get-TdAssetTemplateByName {
    param(
        [parameter(mandatory)]
        $Name
    )
    if (Find-TOPdeskConnection) {
        return (Get-TdAssetTemplates).Where({$_.name -eq $Name})
    }
}
function Get-TdAssets {
    if (Find-TOPdeskConnection) {
        return (Invoke-RestMethod -Uri "$topdeskUrl/tas/api/assetmgmt/templates" -ContentType "application/json" -Method GET -Headers $topdeskAuthenticationHeader).dataSet
    }
}
function Get-TdAssetsByTemplateName {
    param(
        [parameter(mandatory)]
        [STRING]$TemplateName
    )
    if (Find-TOPdeskConnection) {
        $templateId = Get-TdAssetTemplateByName -Name $TemplateName
        return (Invoke-RestMethod -Uri "$topdeskUrl/tas/api/assetmgmt/templates/$templateId" -ContentType "application/json" -Method GET -Headers $topdeskAuthenticationHeader).dataSet
    }
}

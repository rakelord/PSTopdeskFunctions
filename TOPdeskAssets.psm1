#Requires -Modules TOPdeskConnect
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
        [STRING]$Name
    )
    if (Find-TOPdeskConnection) {
        $templateId = Get-TdAssetTemplateByName -Name $Name
        return (Invoke-RestMethod -Uri "$topdeskUrl/tas/api/assetmgmt/templates/$templateId" -ContentType "application/json" -Method GET -Headers $topdeskAuthenticationHeader).dataSet
    }
}
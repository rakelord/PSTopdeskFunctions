Function Connect-TOPdeskAPI {
    <#
    .SYNOPSIS
    Connect to the Topdesk API
    
    .DESCRIPTION
    Connect to the Topdesk API and generate a Token variable that can be used with your own Invoke-RestMethod commands '$topdeskAuthenticationHeader'
    All Functions within this Module already has this variable implemented.
    
    .PARAMETER Url
    Your Topdesk Url
    
    .PARAMETER LoginName
    The username of the account with the App Password

    .PARAMETER Secret
    App secret
    
    .PARAMETER LogToFile
    Connect to PSLoggingFunctions module, read more on GitHub, it create a Log folder in your directory if set to True
    
    .EXAMPLE
    Connect-TopdeskAPI -Url "https://topdesk.internal.local" -LoginName $TopdeskApplicationID -Secret $TopdeskAPISecret -LogToFile $False
    
    OUTPUT
    Topdesk Authenticated: True
    Topdesk URL = https://topdesk.internal.local
    Use Header Connection Variable = $topdeskAuthenticationHeader
    #>
    param(
        [parameter(mandatory)]
        $Url,
        [parameter(mandatory)]
        $LoginName,
        [parameter(mandatory)]
        $Secret,
        [parameter(mandatory)]
        [ValidateSet("True","False")]
        $LogToFile
    )

    $topdeskAuthenticationHeader = @{'Authorization' = "Basic $([Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("$($LoginName):$($Secret)")))"}

    Write-Log -Message "Connecting to Topdesk API" -Active $LogToFile
    Write-Host "Connecting to Topdesk API"

    $testConnection = Invoke-RestMethod -Uri "$Url/tas/api/version" -ContentType "application/json" -Method GET -Headers $topdeskAuthenticationHeader
    $global:TopdeskAuthenticated = $false
    if ($testConnection){
        $global:topdeskAuthenticated = $true
        $global:topdeskUrl = $Url
        Write-Log -Message "Topdesk Authenticated: $TopdeskAuthenticated" -Active $LogToFile
        Write-Log -Message "Topdesk URL = $TopdeskUrl" -Active $LogToFile
        Write-Host "Topdesk Authenticated: $TopdeskAuthenticated`nTopdesk URL = $TopdeskUrl`nUse Header Connection Variable ="'$topdeskAuthenticationHeader'
        $global:topdeskAuthenticationHeader = $topdeskAuthenticationHeader
        return ""
    }
    Write-Log -Message "Topdesk Authenticated: $TopdeskAuthenticated" -Active $LogToFile
    Write-Host "Topdesk Authenticated: $TopdeskAuthenticated"
    return $false
}

function Find-TopdeskConnection {
    if (!$topdeskAuthenticated){
        Write-Warning "Topdesk API is not authenticated, you need to run Connect-TOPdeskAPI and make sure you put in the correct credentials!"
        return $false
    }
    return $true
}

Function Get-TopdeskSuppliers {
    param(
        [parameter(mandatory)]
        [ValidateSet("true","false")]
        $LogToFile
    )
    if (Find-TopdeskConnection) {
        $Suppliers = Invoke-TryCatchLog -InfoLog "Getting all TOPdesk suppliers" -LogToFile $LogToFile -ScriptBlock {
            (Invoke-RestMethod -Uri "$topdeskUrl/tas/api/suppliers" -Method GET -Headers $topdeskAuthenticationHeader) | Select-Object name,id
        }
        return $Suppliers
    }
}

Function Get-TopdeskBranch {
    param(
        $BranchName,
        [parameter(mandatory)]
        [ValidateSet("true","false")]
        $LogToFile
    )
    if (Find-TopdeskConnection) {
        $Uri = "$topdeskUrl/tas/api/branches?query=name=='$BranchName'" + '&$fields=name,id,optionalFields1,optionalFields2'
        $Branch = Invoke-TryCatchLog -InfoLog "Retrieving TOPdesk Branch with Name: $BranchName" -LogToFile $LogToFile -ScriptBlock {
            Invoke-RestMethod -Uri $Uri -ContentType "application/json" -Method GET -Headers $topdeskAuthenticationHeader
        }
        return $Branch
    }
}

Function Get-TopdeskBranches {
    param(
        [parameter(mandatory)]
        [ValidateSet("true","false")]
        $LogToFile
    )
    if (Find-TopdeskConnection) {
        $Uri = "$topdeskUrl/tas/api/branches?" + '$fields=name,id,optionalFields1,optionalFields2'
        $Branch = Invoke-TryCatchLog -InfoLog "Retrieving TOPdesk Branches: $BranchName" -LogToFile $LogToFile -ScriptBlock {
            Invoke-RestMethod -Uri $Uri -ContentType "application/json" -Method GET -Headers $topdeskAuthenticationHeader
        }
        return $Branch
    }
}

Function Get-TopdeskAssetDropdownOptions {
    param(
        [parameter(mandatory)]
        $DropdownName,
        [parameter(mandatory)]
        [ValidateSet("true","false")]
        $LogToFile
    )
    if (Find-TopdeskConnection) {
        $Dropdown = Invoke-TryCatchLog -InfoLog "Retrieving all Topdesk Assets available Dropdown Options: $DropdownName" -LogToFile $LogToFile -ScriptBlock { 
            (Invoke-RestMethod -Uri "$topdeskUrl/tas/api/assetmgmt/dropdowns/$($DropdownName)?field=name" -ContentType "application/json" -Method GET -Headers $topdeskAuthenticationHeader).results
        }
        return $Dropdown
    }
}

function Get-TopdeskAssets {
    <#
    .SYNOPSIS
    Retrieve all devices from TOPdesk asset registry.
    
    .DESCRIPTION
    Retrieve all devices from TOPdesk asset registry.
    
    .PARAMETER Template
    Which template to return, for example Computer or Mobile phone

    .PARAMETER excludeArchived
    Does what is says, it excludes all archived assets
    
    .PARAMETER LogToFile
    This parameter is connected to the Module PSLoggingFunctions mot information can be found on the GitHub.
    https://github.com/rakelord/PSLoggingFunctions
    
    .EXAMPLE
    Return all Computers and exclude archived
    Get-TopdeskDevices -Template 'Computer' -excludeArchived -LogToFile $True
    
    Get-TopdeskDevices -LogToFile $False
    #>
    Param(
        [string]$Template,
        [switch]
        $excludeArchived,
        [parameter(mandatory)]
        [ValidateSet("True","False")]
        $LogToFile
    )

    $templateQuery = ""
    if ($Template){
        $templateQuery = "&templateName=$Template"
    }

    $archivedQuery = ""
    if ($excludeArchived){
        $archivedQuery = "&archived=false"
    }

    if (Find-TopdeskConnection) {
        $DevicesReturned = 0
        $AssetTable = @()

        Write-Log "Retrieving Topdesk Assets $($Template -join ',')" -Active $LogToFile

        # Retrieve the first list of objects, before we are able to filter the list based on the Last object (According to TOPdesks API documentation)
        $pagingUrl = "$($topdeskUrl)/tas/api/assetmgmt/assets?showAssignments&"+'fields=name,id'+$templateQuery+$archivedQuery
        $AssetTable += (Invoke-RestMethod -Headers $topdeskAuthenticationHeader -Uri $pagingUrl -UseBasicParsing -Method "GET" -ContentType "application/json").dataSet
        $Results = $AssetTable
        do {
            $pagingUrl = "$($topdeskUrl)/tas/api/assetmgmt/assets?showAssignments&"+'fields=name,id'+'&$filter=name gt '+"'$(($Results | Select-Object -Last 1).name)'"+$templateQuery+$archivedQuery
            $Results = (Invoke-RestMethod -Headers $topdeskAuthenticationHeader -Uri $pagingUrl -UseBasicParsing -Method "GET" -ContentType "application/json").dataSet
            $AssetTable += $Results
            $DevicesReturned += 50
            
            Clear-Host
            Write-Host "Retrieving All Topdesk Assets: $DevicesReturned$Loading"
            $Loading += "."
            if ($Loading.length -gt 7){$Loading = "."}
        } until (!($Results))

        $AssetTableOutput = Invoke-MultiThreads -RunObjects $AssetTable -ObjectsPerProcess 300 -APIAuthentication $topdeskAuthenticationHeader -ScriptBlock {
            $OutputObject = @()
            foreach ($RunObject in $args[0]){
                $OutputObject += @{
                    unid = $RunObject.unid
                    name = $RunObject.name
                    type_id = $RunObject.type_id
                    type = $RunObject.type
                    archived = $RunObject.archived
                    assignments = $RunObject.'@assignments'
                    parameters = (Invoke-RestMethod -Method "GET" -Uri "https://support.rts.se/tas/api/assetmgmt/assets/$($RunObject.unid)" -Headers $args[1] -ContentType "application/json").data
                }
            }
            $OutputObject
        }

        Write-Host "Topdesk Assets Loaded: $($AssetTableOutput.count)"

        return $AssetTableOutput
    }
}

function Update-TopdeskAsset {
    Param(
        $AssetName,
        $AssetID,
        [parameter(mandatory)]
        $Data,
        [parameter(mandatory)]
        [ValidateSet("true","false")]
        $LogToFile
    )

    if (Find-TopdeskConnection) {
        if (!$AssetID){
            $AssetID = (Get-TopdeskAsset -Name "$AssetName" -LogToFile $False).unid
        }

        if (IsNotNULL($AssetID)) {
            $Data = $Data | ConvertTo-Json -Compress
            Invoke-TryCatchLog -InfoLog "Updating Asset: $AssetID $AssetName" -LogToFile $LogToFile -LogType UPDATE -ScriptBlock {
                Invoke-RestMethod -Uri "$topdeskUrl/tas/api/assetmgmt/assets/$AssetID" -ContentType "application/json" -Body $Data -Method POST -Headers $topdeskAuthenticationHeader
            }
            Write-Log -Message $Data -Active $LogToFile
        }
    }
}
function Get-TopdeskAsset {
    param(
        [parameter(mandatory)]
        $Name,
        [parameter(mandatory)]
        [ValidateSet("True","False")]
        $LogToFile
    )
    if (Find-TopdeskConnection) {
        $Asset = Invoke-TryCatchLog -InfoLog "Retrieving Topdesk Asset: $Name" -LogToFile $LogToFile -ScriptBlock {
            $Uri = "$topdeskUrl/tas/api/assetmgmt/assets?showAssignments"+'&$filter'+"=name eq '$Name'"
            (Invoke-RestMethod -Uri $Uri -ContentType "application/json" -Method GET -Headers $topdeskAuthenticationHeader).dataSet
        }
        return $Asset
    }
} 

function Disable-TopdeskAsset {
    param(
        $AssetID,
        $AssetName,
        [parameter(mandatory)]
        [ValidateSet("true","false")]
        $LogToFile
    )
    if (Find-TopdeskConnection) {
        if (!$AssetID){
            $AssetID = (Get-TopdeskAsset -Name "$AssetName" -LogToFile $False).unid
        }

        $archiveReason = @{
            reasonId = "919dd4db-cc43-5340-a515-aa934722af75"
        } | ConvertTo-Json -Compress

        Invoke-TryCatchLog -InfoLog "Archiving Topdesk Asset: $AssetID $AssetName" -LogType DELETE -LogToFile $LogToFile -ScriptBlock {
            Invoke-RestMethod -Uri "$topdeskUrl/tas/api/assetmgmt/assets/$AssetID/archive" -ContentType "application/json" -Method POST -Body $archiveReason -Headers $topdeskAuthenticationHeader
        }
    }
}

function Enable-TopdeskAsset {
    param(
        $AssetName,
        $AssetID,
        [parameter(mandatory)]
        [ValidateSet("true","false")]
        $LogToFile
    )
    if (Find-TopdeskConnection) {
        if (!$AssetID){
            $AssetID = (Get-TopdeskAsset -Name "$AssetName" -LogToFile $False).unid
        }

        Invoke-TryCatchLog -InfoLog "Unarchiving Topdesk Asset $AssetID $AssetName" -LogType ADD -LogToFile $LogToFile -ScriptBlock {
            Invoke-RestMethod -Uri "$topdeskUrl/tas/api/assetmgmt/assets/$AssetID/unarchive" -ContentType "application/json" -Method POST -Headers $topdeskAuthenticationHeader
        }
    }
}

Function New-TopdeskAssetAssignment { #Assign Companies / Persons to Asset
    param(
        [parameter(mandatory)]
        [ValidateSet("person","branch")]
        $AssignmentType,
        [parameter(mandatory)]
        $AssignmentObjectID, #ID of the Person or Branch depending on above choice
        $AssetID,
        $AssetName,
        [parameter(mandatory)]
        [ValidateSet("true","false")]
        $LogToFile
    )

    if (Find-TopdeskConnection) {
        if (!$AssetID){
            $AssetID = (Get-TopdeskAsset -Name "$AssetName" -LogToFile $False).unid
        }
        
        if ((IsNotNULL($AssignmentObjectID)) -AND (IsNotNULL($AssetID))){

            $linkObject = @{
                "assetIds" = @($AssetID)
                "linkType" = $AssignmentType
                "linkToId" = $AssignmentObjectID
            } | ConvertTo-Json -Compress

            Invoke-TryCatchLog -InfoLog "Assigning $AssignmentType : $AssignmentObjectID to Asset $AssetID $AssetName" -LogToFile $LogToFile -LogType CREATE -ScriptBlock {
                Invoke-RestMethod -Uri "$topdeskUrl/tas/api/assetmgmt/assets/assignments" -ContentType "application/json" -Body $linkObject -Method PUT -Headers $topdeskAuthenticationHeader
            }
        }
    }
}

function New-TopdeskAsset {
    Param(
        [parameter(mandatory)]
        $Data,
        [parameter(mandatory)]
        [ValidateSet("True","False")]
        $LogToFile
    )
    if (Find-TopdeskConnection){
        Invoke-TryCatchLog -InfoLog "Creating new Topdesk Asset: $Data" -LogType "CREATE" -LogToFile $LogToFile -ScriptBlock {
            Invoke-RestMethod -Uri "$topdeskUrl/tas/api/assetmgmt/assets" -ContentType "application/json" -Body $Data -Method POST -Headers $topdeskAuthenticationHeader
        }
    }
}

function Get-TopdeskAssetTemplates {
    Param(
        [parameter(mandatory)]
        [ValidateSet("True","False")]
        $LogToFile
    )
    if (Find-TopdeskConnection){
        Invoke-TryCatchLog -InfoLog "Retrieve Topdesk Asset Templates" -LogToFile $LogToFile -ScriptBlock {
            (Invoke-RestMethod -Uri "$topdeskUrl/tas/api/assetmgmt/templates" -ContentType "application/json" -Method "GET" -Headers $topdeskAuthenticationHeader).dataSet
        }
    }
}
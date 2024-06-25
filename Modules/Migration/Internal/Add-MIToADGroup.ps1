function Add-MIToADGroup {
    param(
        [Parameter(Mandatory)]
        [string]$MIName,

        [Parameter(Mandatory)]
        [string]$ADGroupName, 

        [Parameter(Mandatory)]
        [string]$ClientId,

        [Parameter(Mandatory)]
        [string]$ClientSecret,

        [Parameter(Mandatory)]
        [string]$TenantId
    )


    function Invoke-GraphApi {
        param (
            [Parameter(Mandatory)]
            [string]$UriPath,

            [Parameter(Mandatory)]
            [string]$Method,

            [Parameter(Mandatory=$false)]
            [PSCustomObject]$Body
        )

        Write-LogDebug "Invoking Graph API with UriPath: $UriPath, Method: $Method"
        
        $headers = @{
            Authorization  = "Bearer $accessToken"
            "Content-Type" = "application/json"
        }

        $jsonBody = $null
        if ($null -ne $Body) {
            $jsonBody = $Body | ConvertTo-Json
            Write-LogDebug "JSON body for API request: $jsonBody"
        }

        $response = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/$($UriPath)" -Method $Method -Headers $headers -Body $jsonBody

        return $response
    }
    
    function Get-AADGroup {
        param (
            [Parameter(Mandatory)]
            [string]$GroupName
        )
        
        Write-LogInfo "Getting AAD Group $GroupName"
        $groupUriPath = "/groups?`$filter=displayName eq '$GroupName'&`$select=id,displayName"

        $response = Invoke-GraphApi -UriPath $groupUriPath -Method Get

        if ($response.value.Count -eq 1) {
            Write-Debug "Groud Id: $($response.value[0].id) for group $GroupName"
            return $response.value[0]
        }
        else {
            Write-Error "Group $GroupName not found"
            return $null
        }
    }

    function Get-ServicePrincipal {
        param (
            [Parameter(Mandatory)]
            [string]$SPName
        )

        Write-LogInfo "Getting Service Principal $SPName"
        $spnUriPath = "/servicePrincipals?`$filter=displayName eq '$SPName'&`$select=id,displayName"

        $response = Invoke-GraphApi -UriPath $spnUriPath -Method Get 

        if ($response.value.Count -eq 1) {
            Write-Debug "Service Principal Id: $($response.value[0].id) for SP $SPName"
            return $response.value[0]
        }
        else {
            Write-Error "Service Principal $SPName not found"
            return $null
        }
    }

    function Add-GroupMember {
        param (
            [Parameter(Mandatory)]
            [string]$GroupId,
    
            [Parameter(Mandatory)]
            [string]$DirectoryObjectId
        )
    
        Write-LogInfo "Checking if $DirectoryObjectId is already a member of group $GroupId"
    
        $checkMembershipUriPath = "/groups/$GroupId/members?`$count=true&`$filter=id eq '$DirectoryObjectId'"
        $isMember = Invoke-GraphApi -UriPath $checkMembershipUriPath -Method Get
    
        if ($isMember -eq 0) {
            Write-LogInfo "Adding $MIName to group $ADGroupName"
    
            $groupsUriPath = "/groups/$GroupId/members/`$ref"
    
            $body = @{
                "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$DirectoryObjectId"
            }
    
            $response = Invoke-GraphApi -UriPath $groupsUriPath -Method Post -Body $body
    
            Write-LogInfo "Added $MIName to group $ADGroupName"
            
            return $response
        } else {
            Write-LogInfo "$MIName is already a member of group $ADGroupName"
        }
    }

    
    $accessToken = Get-AccessToken -ClientId $ClientId -ClientSecret $ClientSecret -TenantId $TenantId -ResourceUrl "https://graph.microsoft.com"
    
    $aadGroup = Get-AADGroup -GroupName $ADGroupName

    if ($aadGroup) {
        $miId = Get-ServicePrincipal -SPName $MIName 
        if ($miId) {
            Add-GroupMember -GroupId $aadGroup.id -DirectoryObjectId $miId.id | Out-Null
        }
    }
}
<#

- create capacity
- create 6 workspaces (dev,dev-dwh, etc)
- create dwh
- create pipeliney things

- fabric-cicd deployments
- deployment pipelines for dwh
- oh look the change didn't actually go into source control

#>

# connecting with Azure PowerShell to get a token
Connect-AzAccount

# get the token for the Fabric API
$token = (Get-AzAccessToken -AsSecureString:$false -ResourceUrl "https://api.fabric.microsoft.com").Token
$headers = @{
    'Content-Type'  = 'application/json'
    'Authorization' = "Bearer $token"
}

# create a new workspace
$body = @{
    "displayName" = "Workspace-API"
    "description" = "This is a new workspace created by an API call."
}
$apiParams = @{
    Uri = "https://api.fabric.microsoft.com/v1/workspaces"
    Method = 'Post'
    Headers = $headers
    Body = ($body | ConvertTo-Json) 
}
Invoke-RestMethod @apiParams

# But this is PSConfEU, so let's use the FabricTools module instead of REST API calls

# get the dev module right now - will change to proper module
Import-Module C:\github\FabricTools\output\module\FabricTools\0.0.1\FabricTools.psd1 -force

# Since we ran Connect-AzAccount, we can use the FabricTools module to do the rest
Get-FabricWorkspace | Format-Table

# Get that workspace that I created 
Get-FabricWorkspace -WorkspaceName "Workspace-API" -OutVariable workspace

# Let's remove that one
Remove-FabricWorkspace -WorkspaceId $workspace.Id

# and then let's create 6 for our full demos
$workspaces = @(
    "dev",
    "dev-dwh",
    "test",
    "test-dwh",
    "prod",
    "prod-dwh"
)
$workspaces | ForEach-Object {
    $params = @{
        WorkspaceName        = $_
        WorkspaceDescription = ("This is the {0} workspace created by FabricTools." -f $_)
    }
    New-FabricWorkspace @params
}

# to be able to use the workspace we need a capacity
Get-FabricCapacity | Format-Table

# let's select using out-gridview
$capacity = Get-FabricCapacity | Out-GridView -PassThru

# add capacity to the workspaces
$workspaces | ForEach-Object {
    $params = @{
        WorkspaceId = (Get-FabricWorkspace -WorkspaceName $_).Id
        CapacityId  = $capacity.Id
    }
    Register-FabricWorkspaceToCapacity @params
}


# let's put a lakehouse in the dwh workspaces
$workspaces | Where-Object { $_ -like "*dwh*" } | ForEach-Object {
    $params = @{
        WorkspaceId = (Get-FabricWorkspace -WorkspaceName $_).Id
        LakehouseName = "MyLakehouse"
        LakehouseDescription = "This is a lakehouse created by FabricTools."
    }
    New-FabricLakehouse @params
}


# Let's put a pipeline in the non dwh ones - #TODO: this doesn't work
# these are data pipelines, for moving things around
# [2025-05-17 15:37:44] [Error] Failed to create DataPipeline. Error: Response status code does not indicate success: 400 (Bad Request).      
$workspaces | Where-Object { $_ -notlike "*dwh*" } | ForEach-Object {
    $params = @{
        WorkspaceId = (Get-FabricWorkspace -WorkspaceName $_).Id
        DataPipelineName = "MyPipeline"
        DataPipelineDescription = "This is a pipeline created by FabricTools."
    }
    New-FabricDataPipeline @params
}


# clear up workspaces
$workspaces | ForEach-Object {
    Remove-FabricWorkspace -WorkspaceId (Get-FabricWorkspace -WorkspaceName $_).Id
}

<#
PowerShell 💜 Fabric
- Remember all the deployment tools rely on API calls

- Let's look at how to deploy Fabric resources using PowerShell
    - create capacity
    - create 6 workspaces (dev,dev-dwh, etc)
    - create data things - data warehouse, lakehouse, sql database
    - create pipeliney things - not cicd... but data pipelines

- Then we'll take a look at the Fabric GUI 😱
    - deployment pipelines for dwh
    - oh look the change didn't actually go into source control

#>

<#########################################
We can just call the API with PowerShell
##########################################>

# connecting with Azure PowerShell to get a token
Connect-AzAccount

# get the token for the Fabric API
$secureToken = (Get-AzAccessToken -AsSecureString:$false -ResourceUrl "https://api.fabric.microsoft.com").Token

# because -AsSecureString:$false still gives me a secure string, I need to convert it to a regular string
$token = $secureToken | ConvertFrom-SecureString -AsPlainText
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

<#########################################
# Introducing FabricTools!

# But this is PSConfEU, and we like PowerShell 
# so let's use the FabricTools module instead of REST API calls
##########################################>

# Get the FabricTools module imported
Import-Module FabricTools

# Lets connect to Fabric
Connect-FabricAccount

# Let's see if we can get Workspaces
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

# let's select using Out-GridView
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

# and a sql database
$workspaces | Where-Object { $_ -like "*dwh*" } | ForEach-Object {
    $params = @{
        WorkspaceId = (Get-FabricWorkspace -WorkspaceName $_).Id
        Name = "MySqlDatabase"
        Description = "This is a SQL database created by FabricTools."
    }
    New-FabricSqlDatabase @params
}

# Let's put a pipeline in the non dwh ones
# these are data pipelines, for moving things around
$workspaces | Where-Object { $_ -notlike "*dwh*" } | ForEach-Object {
    $params = @{
        WorkspaceId = (Get-FabricWorkspace -WorkspaceName $_).Id
        DataPipelineName = "MyPipeline"
        DataPipelineDescription = "This is a pipeline created by FabricTools."
    }
    New-FabricDataPipeline @params
}

# Let's get items from a workspace
Get-FabricWorkspace -WorkspaceName dev-dwh | Get-FabricItem

# Let's go to the portal
Invoke-Item "https://fabric.microsoft.com"

# DON'T FORGET TO CLEAN UP AFTERWARDS
# clear up workspaces
$workspaces | ForEach-Object {
    Remove-FabricWorkspace -WorkspaceId (Get-FabricWorkspace -WorkspaceName $_).Id
}

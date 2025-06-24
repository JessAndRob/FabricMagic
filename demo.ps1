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

# Connect to Fabric Account
Connect-FabricAccount

# Let's run some tests to make sure we don't have any things left over from previous demos
$PesterResults = Invoke-Pester -Output None -PassThru

# Make it look pretty using PesterExplorer
# https://github.com/HeyItsGilbert/PesterExplorer
Show-PesterResultTree $PesterResults

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

Start-Process "https://fabric.microsoft.com"

<#########################################
# Introducing FabricTools!

# But this is PSConfEU, and we like PowerShell
# so let's use the FabricTools module instead of REST API calls
##########################################>

# show the version
Get-PSResource FabricTools

# Let's see if we can get Workspaces
Get-FabricWorkspace | Format-Table

# Get that workspace that I created
Get-FabricWorkspace -WorkspaceName "Workspace-API" -OutVariable workspace

# Let's remove that one
Remove-FabricWorkspace -WorkspaceId $workspace.Id

# and then let's create 6 for our full demos
$workspaces = @(
    'dev',
    'dev-dwh',
    'test',
    'test-dwh',
    'prod',
    'prod-dwh'
)
$workspaces | ForEach-Object {
    $params = @{
        WorkspaceName = $_
        WorkspaceDescription = ("This is the {0} workspace created by FabricTools." -f $_)
    }
    New-FabricWorkspace @params
}

$demoWorkspaces = Get-FabricWorkspace | Where-Object { $_.displayName -in $workspaces }

$demoWorkspaces

# to be able to use the workspace we need a capacity
Get-FabricCapacity -OutVariable cap | Format-Table

# let's select using Out-GridView
$capacity = $cap | Out-GridView -PassThru

# add capacity to the workspaces
$demoWorkspaces | ForEach-Object {
    $params = @{
        WorkspaceId = $_.id
        CapacityId  = $capacity.Id
    }
    Register-FabricWorkspaceToCapacity @params
}

# let's put a lakehouse in the dwh workspaces
$demoWorkspaces | Where-Object { $_.displayName -like "*dwh*" } | ForEach-Object {
    $params = @{
        WorkspaceId = $_.id
        LakehouseName = "LosAngeles"
        LakehouseDescription = ("This is the {0} lakehouse created by FabricTools." -f $_.displayName)
    }
    New-FabricLakehouse @params
}

# and a sql database
$demoWorkspaces | Where-Object { $_.displayName -like "*dwh*" }| ForEach-Object {
    $params = @{
        workspaceId = $_.id
        Name = "MySqlDatabase"
        Description = "This is a SQL database created by FabricTools."
    }
    New-FabricSqlDatabase @params
}

$demoworkspaces | Get-FabricSQLDatabase

# Let's put a pipeline in the non dwh ones
# these are data pipelines, for moving things around
$demoWorkspaces | Where-Object { $_.displayName -notlike "*dwh*" } | ForEach-Object {
    $params = @{
        workspaceId = $_.id
        DataPipelineName = "JefferySnoverKingof"
        DataPipelineDescription = "This is a pipeline created by FabricTools for {0}." -f $_.displayName
    }
    New-FabricDataPipeline @params
}

# Let's get items from a workspace
Get-FabricWorkspace -WorkspaceName dev-dwh | Get-FabricItem

# Lets see all of the resources that have commands.
Get-Command -Module FabricTools -Verb Get

# Let's go to the portal
Start-Process "https://fabric.microsoft.com"

# DON'T FORGET TO CLEAN UP AFTERWARDS
# clear up workspaces
$demoWorkspaces | Where-Object { $_.displayName -in $workspaces } | ForEach-Object {
    Remove-FabricWorkspace -WorkspaceId $_.id -Confirm:$false
}

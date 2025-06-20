Describe "These should all pass before the demo" {
    BeforeAll {
        $vars = Get-Variable
        $workspacesTesting = Get-FabricWorkspace
        $lakehousesTesting = $workspacesTesting | ForEach-Object {
            Get-FabricLakehouse -WorkspaceId $_.id
        }
        $sqlDatabasesTesting = $workspacesTesting | Get-FabricSqlDatabase
        $dataPipelinesTesting = $workspacesTesting | ForEach-Object {
            Get-FabricDataPipeline -WorkspaceId $_.id
        }
    }

    Context "Session" {
        It "Should not have the <_> variable" -TestCases @('securetoken', 'token', 'headers', 'body', 'apiParams', 'workspace', 'workspaces', 'capacity', 'params','workspaceName',
        'workspaceId') {
            $vars.Name | Should -Not -Contain $_
        }
    }
    Context "Workspaces" {
        It "Should not have the <_> workspace" -TestCases @('Workspace-API', 'dev', 'dev-dwh', 'test', 'test-dwh', 'prod', 'prod-dwh') {

            $workspacesTesting.displayName | Should -Not -Contain $_ -Because "We need to demo creating $_ workspace"
        }
    }
    Context "Lakehouses" {
        It "Should not have the <_> lakehouse" -TestCases @('LosAngeles', 'MyLakehouse') {

            $lakehousesTesting.displayName | Should -Not -Contain $_
        }
    }
    Context "SQL Databases" {
        It "Should not have the <_> SQL Database" -TestCases @('MySqlDatabase') {
            $SqlDatabasesTesting.displayName | Should -Not -Contain $_
        }
    }
    Context "Data Pipelines" {
        It "Should not have the <_> data pipeline" -TestCases @('MyPipeline','JefferySnoverKingOf') {
            $dataPipelinesTesting.displayName | Should -Not -Contain $_
        }
    }
}
$DSCModuleName      = 'xNetworking'
$DSCResourceName    = 'MSFT_xFirewall'

#region HEADER
Import-Module DSCResource.Tools\TestHelper.psm1
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $DSCModuleName `
    -DSCResourceName $DSCResourceName `
    -TestType Integration 
#endregion

# Using try/finally to always cleanup even if something awful happens.
try
{


    #region Integration Tests
    <#
      This file exists so we can load the test file without necessarily having xNetworking in
      the $env:PSModulePath. Otherwise PowerShell will throw an error when reading the Pester File.
    #>
    $ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "$DSCResourceName.config.ps1"
    . $ConfigFile
    
    Describe "$($DSCResourceName)_Integration" {
        #region DEFAULT TESTS
        It 'Should compile without throwing' {
            {
                [System.Environment]::SetEnvironmentVariable('PSModulePath',
                    $env:PSModulePath,[System.EnvironmentVariableTarget]::Machine)
                Invoke-Expression -Command "$($DSCResourceName)_Config -OutputPath `$TestEnvironment.WorkingFolder"
                Start-DscConfiguration -Path (Join-Path -Path $env:Temp -ChildPath $DSCResourceName) `
                    -ComputerName localhost -Wait -Verbose -Force
            } | Should not throw
        }

        It 'should be able to call Get-DscConfiguration without throwing' {
            { Get-DscConfiguration -Verbose -ErrorAction Stop } | Should Not throw
        }
        #endregion

        It 'Should have set the resource and all the parameters should match' {
            # Get the Rule details
            $firewallRule = Get-NetFireWallRule -Name $rule.Name
            $Properties = @{
                AddressFilters       = @(Get-NetFirewallAddressFilter -AssociatedNetFirewallRule $FirewallRule)
                ApplicationFilters   = @(Get-NetFirewallApplicationFilter -AssociatedNetFirewallRule $FirewallRule)
                InterfaceFilters     = @(Get-NetFirewallInterfaceFilter -AssociatedNetFirewallRule $FirewallRule)
                InterfaceTypeFilters = @(Get-NetFirewallInterfaceTypeFilter -AssociatedNetFirewallRule $FirewallRule)
                PortFilters          = @(Get-NetFirewallPortFilter -AssociatedNetFirewallRule $FirewallRule)
                Profile              = @(Get-NetFirewallProfile -AssociatedNetFirewallRule $FirewallRule)
                SecurityFilters      = @(Get-NetFirewallSecurityFilter -AssociatedNetFirewallRule $FirewallRule)
                ServiceFilters       = @(Get-NetFirewallServiceFilter -AssociatedNetFirewallRule $FirewallRule)
            }

            # Use the Parameters List to perform these tests
            foreach ($parameters in $ParameterList)
            {
                $ParameterSource = (Invoke-Expression -Command "`$($($parameters.source))")
                $ParameterNew = (Invoke-Expression -Command "`$rule.$($parameters.name)")
                $ParameterSource | Should Be $ParameterNew
            }
        }
    }
    #endregion


}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
    
    Remove-NetFirewallRule -Name $rule.Name
}

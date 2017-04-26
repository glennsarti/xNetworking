$NetAdapter = Get-NetAdapter | Where-Object {$_.NdisVersion -ge 6} | Select-Object -First 1
$TestEnableLsoIPv6 = [PSObject]@{
    Name     = $NetAdapter.Name
    Protocol = 'IPv6'
    State    = $true
}

configuration MSFT_xNetAdapterLso_Config {
    Import-DscResource -ModuleName xNetworking
    node localhost {
        xNetAdapterLso Integration_Test {
            Name        = $TestEnableLsoIPv6.Name
            Protocol    = $TestEnableLsoIPv6.Protocol
            State       = $TestEnableLsoIPv6.State
        }
    }
}

# ==============================================================================
# BalconyBloomCo Dawn 16.0 Automated Test Runner
# Executes Tiers 1-4 Test Suites
# Author: teamwork_preview_test_writer
# ==============================================================================

[CmdletBinding()]
param(
    [ValidateSet(1, 2, 3, 4)]
    [int]$Tier = 0,

    [string]$Filter = "",

    [switch]$Detailed = $false
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$frameworkPath = Join-Path $scriptDir "framework.ps1"

if (-not (Test-Path $frameworkPath)) {
    Write-Error "Framework not found at $frameworkPath"
    exit 2
}

. $frameworkPath

if ($Filter) {
    $global:TestContext.Filter = $Filter
}

$tierFiles = @{
    1 = @(
        (Join-Path $scriptDir "tier1_features/test_r1_config_schema.ps1"),
        (Join-Path $scriptDir "tier1_features/test_r2_design_system.ps1"),
        (Join-Path $scriptDir "tier1_features/test_r3_accessibility_perf.ps1"),
        (Join-Path $scriptDir "tier1_features/test_r4_native_purchasing.ps1")
    )
    2 = @(
        (Join-Path $scriptDir "tier2_boundaries/test_boundary_corner_cases.ps1")
    )
    3 = @(
        (Join-Path $scriptDir "tier3_pairwise/test_pairwise_combinations.ps1")
    )
    4 = @(
        (Join-Path $scriptDir "tier4_workloads/test_workload_journeys.ps1")
    )
}

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host " BalconyBloomCo Shopify Dawn 16.0 -- Automated Test Suite" -ForegroundColor Cyan
Write-Host " Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan

$selectedTiers = if ($Tier -gt 0) { @($Tier) } else { @(1, 2, 3, 4) }

$suiteWatch = [System.Diagnostics.Stopwatch]::StartNew()

foreach ($t in $selectedTiers) {
    $global:TestContext.CurrentTier = "Tier $t"
    Write-Host ""
    Write-Host "=== EXECUTING TIER $t ===" -ForegroundColor Magenta
    foreach ($file in $tierFiles[$t]) {
        if (Test-Path $file) {
            . $file
        } else {
            Write-Warning "Test file missing: $file"
        }
    }
}

$suiteWatch.Stop()

# --- Report Generation ---
Write-Host ""
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host " TEST EXECUTION SUMMARY" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan

$results = $global:TestContext.Results
$tierGroups = $results | Group-Object Tier

$fmtHeader = '{0,-10} | {1,8} | {2,8} | {3,8} | {4,10}'
$fmtTier   = '{0,-10} | {1,8} | {2,8} | {3,8} | {4,9}%'

$headerLine = [string]::Format($fmtHeader, 'Tier', 'Total', 'Passed', 'Failed', 'Pass Rate')
Write-Host $headerLine
Write-Host ("-" * 54)

foreach ($tg in $tierGroups) {
    $tTotal = $tg.Group.Count
    $tPass = ($tg.Group | Where-Object { $_.Status -eq "PASS" }).Count
    $tFail = ($tg.Group | Where-Object { $_.Status -eq "FAIL" }).Count
    $rate = if ($tTotal -gt 0) { [Math]::Round(($tPass / $tTotal) * 100, 1) } else { 0 }
    $tierLine = [string]::Format($fmtTier, $tg.Name, $tTotal, $tPass, $tFail, $rate)
    Write-Host $tierLine
}

Write-Host ("-" * 54)
$totalTests = $global:TestContext.Total
$totalPassed = $global:TestContext.Passed
$totalFailed = $global:TestContext.Failed
$overallRate = if ($totalTests -gt 0) { [Math]::Round(($totalPassed / $totalTests) * 100, 1) } else { 0 }
$overallColor = if ($totalFailed -eq 0) { 'Green' } else { 'Yellow' }
$overallLine = [string]::Format($fmtTier, 'OVERALL', $totalTests, $totalPassed, $totalFailed, $overallRate)
Write-Host $overallLine -ForegroundColor $overallColor

Write-Host ""
Write-Host "Total Execution Time: $($suiteWatch.ElapsedMilliseconds) ms"

if ($totalFailed -gt 0) {
    Write-Host ""
    Write-Host "--- FAILED TESTS BREAKDOWN ($totalFailed) ---" -ForegroundColor Red
    foreach ($r in ($results | Where-Object { $_.Status -eq "FAIL" })) {
        Write-Host "  * [$($r.TestId)] $($r.Description)" -ForegroundColor Red
        Write-Host "    Group: $($r.Group)" -ForegroundColor DarkGray
        Write-Host "    Reason: $($r.Error)" -ForegroundColor DarkYellow
    }
    Write-Host ""
    Write-Host "Suite Status: FAILED with $totalFailed failing assertions (Baseline Gate Active)." -ForegroundColor Red
    exit 1
} else {
    Write-Host ""
    Write-Host "Suite Status: PASSED (100% Green)." -ForegroundColor Green
    exit 0
}

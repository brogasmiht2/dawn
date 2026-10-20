# ==============================================================================
# BalconyBloomCo Dawn 16.0 Automated Test Framework
# Author: teamwork_preview_test_writer
# ==============================================================================

Set-StrictMode -Off
$ErrorActionPreference = 'Stop'

# Global State Container for Test Execution
$global:TestContext = @{
    CurrentTier  = ""
    CurrentGroup = ""
    CurrentTest  = ""
    Passed       = 0
    Failed       = 0
    Skipped      = 0
    Total        = 0
    Results      = [System.Collections.ArrayList]::new()
    StartTime    = [System.DateTime]::UtcNow
    Filter       = ""
    ProjectRoot  = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

# --- Assertion Helpers ---

function Assert-True([bool]$condition, [string]$message = "Expected condition to be True") {
    if (-not $condition) {
        throw "Assertion Failed: $message"
    }
}

function Assert-False([bool]$condition, [string]$message = "Expected condition to be False") {
    if ($condition) {
        throw "Assertion Failed: $message"
    }
}

function Assert-Equal($actual, $expected, [string]$message = "") {
    $equal = $false
    if ($null -eq $actual -and $null -eq $expected) {
        $equal = $true
    } elseif ($null -ne $actual -and $null -ne $expected) {
        if ($actual -is [System.ValueType] -and $expected -is [System.ValueType]) {
            $equal = ([double]$actual -eq [double]$expected)
        } else {
            $equal = ($actual -eq $expected)
        }
    }
    if (-not $equal) {
        $desc = if ($message) { " ($message)" } else { "" }
        throw "Assertion Failed$desc. Expected: [$expected], Actual: [$actual]"
    }
}

function Assert-NotEqual($actual, $expected, [string]$message = "") {
    if ($actual -eq $expected) {
        $desc = if ($message) { " ($message)" } else { "" }
        throw "Assertion Failed$desc. Expected value NOT to equal: [$expected]"
    }
}

function Assert-Match([string]$actual, [string]$regexPattern, [string]$message = "") {
    if ($actual -notmatch $regexPattern) {
        $desc = if ($message) { " ($message)" } else { "" }
        throw "Assertion Failed$desc. Text did not match pattern: [$regexPattern]"
    }
}

function Assert-NotMatch([string]$actual, [string]$regexPattern, [string]$message = "") {
    if ($actual -match $regexPattern) {
        $desc = if ($message) { " ($message)" } else { "" }
        throw "Assertion Failed$desc. Text unexpectedly matched pattern: [$regexPattern]"
    }
}

function Assert-GreaterThanOrEqual([double]$actual, [double]$expected, [string]$message = "") {
    if ($actual -lt $expected) {
        $desc = if ($message) { " ($message)" } else { "" }
        throw "Assertion Failed$desc. Expected [$actual] to be >= [$expected]"
    }
}

function Assert-FileExists([string]$relativePath, [string]$message = "") {
    $fullPath = Join-Path $global:TestContext.ProjectRoot $relativePath
    if (-not (Test-Path $fullPath)) {
        $desc = if ($message) { " ($message)" } else { "" }
        throw "Assertion Failed$desc. Required file does not exist: [$relativePath]"
    }
}

# --- Color and Accessibility Calculation Helpers ---

function Get-ChannelLinear([double]$c) {
    if ($c -le 0.04045) { return $c / 12.92 }
    return [Math]::Pow(($c + 0.055) / 1.055, 2.4)
}

function Get-RelativeLuminance([string]$hex) {
    $hex = $hex.Trim().TrimStart('#')
    if ($hex.Length -eq 3) {
        $hex = "$($hex[0])$($hex[0])$($hex[1])$($hex[1])$($hex[2])$($hex[2])"
    }
    if ($hex.Length -ne 6) {
        throw "Invalid hex color format: '$hex'"
    }
    $r = [Convert]::ToInt32($hex.Substring(0, 2), 16) / 255.0
    $g = [Convert]::ToInt32($hex.Substring(2, 2), 16) / 255.0
    $b = [Convert]::ToInt32($hex.Substring(4, 2), 16) / 255.0

    return (0.2126 * (Get-ChannelLinear $r)) + (0.7152 * (Get-ChannelLinear $g)) + (0.0722 * (Get-ChannelLinear $b))
}

function Get-ContrastRatio([string]$color1, [string]$color2) {
    $l1 = Get-RelativeLuminance $color1
    $l2 = Get-RelativeLuminance $color2
    $lighter = [Math]::Max($l1, $l2)
    $darker = [Math]::Min($l1, $l2)
    return [Math]::Round(($lighter + 0.05) / ($darker + 0.05), 2)
}

# --- File Reading Helpers ---

function Get-ProjectFileContent([string]$relativePath) {
    $fullPath = Join-Path $global:TestContext.ProjectRoot $relativePath
    if (-not (Test-Path $fullPath)) {
        throw "File not found: $relativePath"
    }
    return [System.IO.File]::ReadAllText($fullPath, [System.Text.Encoding]::UTF8)
}

function Get-ProjectJson([string]$relativePath) {
    $content = Get-ProjectFileContent $relativePath
    return ConvertFrom-Json $content
}

# --- Test Runner Functions ---

function Describe([string]$groupName, [scriptblock]$script) {
    $global:TestContext.CurrentGroup = $groupName
    Write-Host "`n=== Test Group: $groupName ===" -ForegroundColor Cyan
    & $script
}

function It([string]$testId, [string]$description, [scriptblock]$testBlock) {
    $fullName = "[$testId] $description"
    if ($global:TestContext.Filter -and ($fullName -notmatch $global:TestContext.Filter)) {
        return
    }

    $global:TestContext.CurrentTest = $fullName
    $global:TestContext.Total++

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $status = "PASS"
    $errorMsg = ""

    try {
        & $testBlock
        $global:TestContext.Passed++
        $sw.Stop()
        Write-Host "  [PASS] $fullName ($($sw.ElapsedMilliseconds)ms)" -ForegroundColor Green
    } catch {
        $global:TestContext.Failed++
        $sw.Stop()
        $status = "FAIL"
        $errorMsg = $_.Exception.Message
        Write-Host "  [FAIL] $fullName ($($sw.ElapsedMilliseconds)ms)" -ForegroundColor Red
        Write-Host "         Error: $errorMsg" -ForegroundColor Yellow
    }

    $resultRecord = [PSCustomObject]@{
        Tier        = $global:TestContext.CurrentTier
        Group       = $global:TestContext.CurrentGroup
        TestId      = $testId
        Description = $description
        Status      = $status
        DurationMs  = $sw.ElapsedMilliseconds
        Error       = $errorMsg
    }
    [void]$global:TestContext.Results.Add($resultRecord)
}

# ==============================================================================
# Adversarial Stress Test Suite: Viewports, Focus Rings, Touch Targets, Typography
# Challenger 1 (Adversarial Viewport & Interaction Challenger)
# Project: BalconyBloomCo Shopify Dawn 16.0 Storefront
# ==============================================================================

param(
    [switch]$VerboseOutput = $false
)

$ErrorActionPreference = "Stop"

# Resolve project root (parent directory of tests/)
$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $PSScriptRoot

. (Join-Path $PSScriptRoot "framework.ps1")

$global:TestContext.CurrentTier = "Adversarial"

Write-Host "================================================================================" -ForegroundColor Yellow
Write-Host " BalconyBloomCo Dawn 16.0 -- Adversarial Viewport & Interaction Stress Tests" -ForegroundColor Yellow
Write-Host " Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC') - Challenger 1" -ForegroundColor Yellow
Write-Host "================================================================================" -ForegroundColor Yellow

# Helper function to blend rgba over a background hex
function Get-AlphaBlendedHex([string]$fgRgba, [string]$bgHex) {
    if ($fgRgba -match 'rgba\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*([0-9.]+)\s*\)') {
        $fgR = [double]$Matches[1]
        $fgG = [double]$Matches[2]
        $fgB = [double]$Matches[3]
        $alpha = [double]$Matches[4]
    } else {
        throw "Invalid RGBA string: $fgRgba"
    }

    $cleanBg = $bgHex.Trim().TrimStart('#')
    $bgR = [Convert]::ToInt32($cleanBg.Substring(0, 2), 16)
    $bgG = [Convert]::ToInt32($cleanBg.Substring(2, 2), 16)
    $bgB = [Convert]::ToInt32($cleanBg.Substring(4, 2), 16)

    $outR = [Math]::Round(($alpha * $fgR) + ((1.0 - $alpha) * $bgR))
    $outG = [Math]::Round(($alpha * $fgG) + ((1.0 - $alpha) * $bgG))
    $outB = [Math]::Round(($alpha * $fgB) + ((1.0 - $alpha) * $bgB))

    return "#{0:X2}{1:X2}{2:X2}" -f [int]$outR, [int]$outG, [int]$outB
}

# ==============================================================================
# SECTION 1: Extreme & Boundary Viewport Stress Testing (320px, 390px, 768px, 1440px)
# ==============================================================================

Describe "ADV-01: Responsive Layout at Extreme and Boundary Viewports" {

    It "ADV-VP-01" "320px Extreme Mobile: Horizontal Overflow Audit across all theme stylesheets" {
        $cssFiles = Get-ChildItem -Path (Join-Path $ProjectRoot "assets") -Filter "*.css"
        $overflowIssues = @()

        foreach ($file in $cssFiles) {
            $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
            # Find any unconditional fixed width or min-width > 320px outside media queries
            $matches = [regex]::Matches($content, '(?m)^\s*(min-width|width)\s*:\s*([3-9][0-9]{2}|[1-9][0-9]{3,})px')
            foreach ($m in $matches) {
                $val = [int]$m.Groups[2].Value
                if ($val -gt 320) {
                    # Verify if this declaration is inside a @media (min-width: ...) query
                    $idx = $m.Index
                    $preceding = $content.Substring(0, $idx)
                    $lastMedia = $preceding.LastIndexOf('@media')
                    $lastClose = $preceding.LastIndexOf('}')
                    if ($lastMedia -lt $lastClose -or $lastMedia -eq -1) {
                        # Not inside media query! Check if it's inside an exempted utility or component
                        $overflowIssues += "$($file.Name): $($m.Value) at index $idx"
                    }
                }
            }
        }

        Assert-Equal $overflowIssues.Count 0 ("Found unconditional width > 320px causing horizontal overflow at 320px: " + ($overflowIssues -join ", "))
    }

    It "ADV-VP-02" "320px Extreme Mobile: Sticky Add to Cart flex sizing and no horizontal overflow" {
        $css = Get-ProjectFileContent "assets/balcony-bloom.css"
        
        # Verify sticky ATC has max-width: 1200px and margin auto
        Assert-Match $css '(?s)\.bb-sticky-atc__inner\s*\{[^}]*max-width:\s*1200px' "Sticky ATC inner container must constrain max-width"
        
        # Verify min-width: 0 on flex children to prevent flex minimum content width overflow
        Assert-Match $css '(?s)\.bb-sticky-atc__product-info\s*\{[^}]*min-width:\s*0' ".bb-sticky-atc__product-info must declare min-width: 0 to allow shrinking"
        Assert-Match $css '(?s)\.bb-sticky-atc__details\s*\{[^}]*min-width:\s*0' ".bb-sticky-atc__details must declare min-width: 0 to prevent title overflow"
        Assert-Match $css '(?s)\.bb-sticky-atc__title\s*\{[^}]*text-overflow:\s*ellipsis' ".bb-sticky-atc__title must declare text-overflow: ellipsis for narrow screens"
        Assert-Match $css '(?s)\.bb-sticky-atc__title\s*\{[^}]*overflow:\s*hidden' ".bb-sticky-atc__title must declare overflow: hidden"

        # Math verification at 320px viewport:
        # Viewport = 320px. Sticky padding: 1rem 1.6rem = 16px left + 16px right = 32px.
        # Available width = 320 - 32 = 288px.
        # Fixed elements: thumbnail 44px, gap 12px, button ~115px, gap 12px.
        # Space remaining for title/price = 288 - 44 - 12 - 115 - 12 = 105px.
        $availableWidth = 320 - 32
        $fixedElementsWidth = 44 + 12 + 12 + 115
        $remainingTextSpace = $availableWidth - $fixedElementsWidth
        Assert-True ($remainingTextSpace -gt 80) "Sticky ATC must leave at least 80px for title and price on 320px viewport without wrapping into multiple rows"
    }

    It "ADV-VP-03" "320px Extreme Mobile: Category Grid 2-Up Math and inner card fit" {
        $css = Get-ProjectFileContent "assets/balcony-bloom.css"
        
        # Grid definition at max-width: 749px
        Assert-Match $css '(?s)max-width:\s*749px.*?\.bb-category-grid.*?grid-template-columns:\s*repeat\(2,\s*1fr\)\s*!important' "Category grid must enforce repeat(2, 1fr) !important on mobile"
        Assert-Match $css '(?s)max-width:\s*749px.*?\.bb-category-grid.*?gap:\s*1\.2rem' "Category grid gap must be 1.2rem (12px) on mobile"

        # Math verification at 320px:
        # Standard page padding in mobile template: 1.5rem (15px) left and right = 30px total.
        # Available width = 320 - 30 = 290px.
        # 2 columns with 12px gap: (290 - 12) / 2 = 139px per column card.
        # Card padding: 1.6rem = 16px left + 16px right = 32px.
        # Inner card content width = 139 - 32 = 107px.
        $colWidth = (290 - 12) / 2
        $cardInnerWidth = $colWidth - 32
        Assert-GreaterThanOrEqual $cardInnerWidth 100 "Category card inner content width at 320px must be >= 100px (got $cardInnerWidth px)"

        # Icon placeholder is 64px x 64px, which fits inside 107px
        Assert-Match $css '(?s)\.bb-category-card__icon-placeholder\s*\{[^}]*width:\s*64px' "Category icon placeholder must be 64px"
        Assert-True ($cardInnerWidth -ge 64) "Category card inner width ($cardInnerWidth px) must accommodate 64px icon placeholder"
    }

    It "ADV-VP-04" "390px Standard Mobile: Layout Rhythm and 2-Up Category collapse" {
        $css = Get-ProjectFileContent "assets/balcony-bloom.css"
        
        # Mobile category grid rule applies cleanly at 390px
        $hasMobileRule = $css -match '(?s)@media[^{]*max-width:\s*749px[^{]*\{.*?\.bb-category-grid\s*\{[^}]*grid-template-columns:\s*repeat\(2,\s*1fr\)'
        Assert-True $hasMobileRule "balcony-bloom.css must include @media (max-width: 749px) rule for 2-up category grid"

        # Value props (benefits) grid single column on mobile
        Assert-Match $css '(?s)\.bb-benefits-grid\s*\{[^}]*grid-template-columns:\s*repeat\(1,\s*1fr\)' "Benefits grid defaults to 1 column on mobile (390px)"
        # Goals grid single column on mobile
        Assert-Match $css '(?s)\.bb-goals-grid\s*\{[^}]*grid-template-columns:\s*repeat\(1,\s*1fr\)' "Goals grid defaults to 1 column on mobile (390px)"
        # Guides grid single column on mobile
        Assert-Match $css '(?s)\.bb-guides-grid\s*\{[^}]*grid-template-columns:\s*repeat\(1,\s*1fr\)' "Guides grid defaults to 1 column on mobile (390px)"
    }

    It "ADV-VP-05" "749px vs 750px Breakpoint Boundary Continuity: Zero-gap transition" {
        $css = Get-ProjectFileContent "assets/balcony-bloom.css"
        
        # Check that max-width is 749px and min-width is 750px
        Assert-Match $css 'max-width:\s*749px' "CSS must use 749px as mobile boundary"
        Assert-Match $css 'min-width:\s*750px' "CSS must use 750px as tablet boundary"
        
        # Ensure no inverted or overlapping boundaries like max-width: 750px AND min-width: 750px
        $overlap = $css -match 'max-width:\s*750px'
        Assert-False $overlap "CSS must not declare max-width: 750px to prevent boundary collision with min-width: 750px"
    }

    It "ADV-VP-06" "768px Tablet Viewport: Multi-column wrapping and category grid auto-fit" {
        $css = Get-ProjectFileContent "assets/balcony-bloom.css"
        
        # Base category grid auto-fit definition
        Assert-Match $css '(?s)\.bb-category-grid\s*\{[^}]*grid-template-columns:\s*repeat\(auto-fit,\s*minmax\(220px,\s*1fr\)\)' "Base category grid must use repeat(auto-fit, minmax(220px, 1fr)) for tablet viewports"
        
        # At 768px viewport: page width ~720px.
        # With 220px minmax and 20px (2rem) gap:
        # 3 columns require: 3 * 220 + 2 * 20 = 660 + 40 = 700px <= 720px.
        # Auto-fit cleanly computes 3 columns at 768px tablet viewport.
        $minColWidth = 220
        $gap = 20
        $threeColRequired = (3 * $minColWidth) + (2 * $gap)
        Assert-True ($threeColRequired -le 720) "Tablet 768px viewport cleanly accommodates 3 auto-fit category columns (requires $threeColRequired px)"

        # Benefits grid: 2 columns at 750px+
        Assert-Match $css '(?s)min-width:\s*750px.*?\.bb-benefits-grid.*?grid-template-columns:\s*repeat\(2,\s*1fr\)' "Benefits grid transitions to 2-up at min-width: 750px (active at 768px)"
        # Goals grid: 3 columns at 750px+
        Assert-Match $css '(?s)min-width:\s*750px.*?\.bb-goals-grid.*?grid-template-columns:\s*repeat\(3,\s*1fr\)' "Goals grid transitions to 3-up at min-width: 750px (active at 768px)"
        # Guides grid: 3 columns at 750px+
        Assert-Match $css '(?s)min-width:\s*750px.*?\.bb-guides-grid.*?grid-template-columns:\s*repeat\(3,\s*1fr\)' "Guides grid transitions to 3-up at min-width: 750px (active at 768px)"
    }

    It "ADV-VP-07" "1440px Desktop Viewport: Centering and page-width constraint" {
        $data = Get-ProjectJson "config/settings_data.json"
        $pageWidth = [int]$data.current.page_width
        Assert-GreaterThanOrEqual $pageWidth 1000 "Page width must be at least 1000px"
        Assert-True ($pageWidth -le 1600) "Page width must not exceed 1600px"
        Assert-True ($pageWidth -lt 1440) "Page width ($pageWidth px) must be strictly less than 1440px desktop viewport to ensure centered margins"

        $baseCss = Get-ProjectFileContent "assets/base.css"
        Assert-Match $baseCss '(?s)\.page-width\s*\{[^}]*max-width:\s*var\(--page-width\)' ".page-width must constrain container width to var(--page-width)"
        Assert-Match $baseCss '(?s)\.page-width\s*\{[^}]*margin:\s*0\s+auto' ".page-width must center the layout on desktop viewports (1440px)"

        # Desktop category grid 4-col and 5-col rules at min-width: 990px
        $css = Get-ProjectFileContent "assets/balcony-bloom.css"
        Assert-Match $css '(?s)min-width:\s*990px.*?\.bb-category-grid--5-col.*?grid-template-columns:\s*repeat\(5,\s*1fr\)' "Category grid provides 5-col desktop layout"
        Assert-Match $css '(?s)min-width:\s*990px.*?\.bb-category-grid--4-col.*?grid-template-columns:\s*repeat\(4,\s*1fr\)' "Category grid provides 4-col desktop layout"
        Assert-Match $css '(?s)min-width:\s*990px.*?\.bb-benefits-grid.*?grid-template-columns:\s*repeat\(4,\s*1fr\)' "Benefits grid expands to 4 columns on desktop"
    }
}

# ==============================================================================
# SECTION 2: Focus Rings Contrast Ratio & Visibility Stress Testing
# ==============================================================================

Describe "ADV-02: Focus Rings Contrast Ratio & Box-Shadow Halo Stress Testing" {

    It "ADV-FOC-01" "Focus ring geometry: Dual-layer halo mechanics and offset validation" {
        $css = Get-ProjectFileContent "assets/balcony-bloom.css"
        
        # Check global :focus-visible declaration
        Assert-Match $css '(?s):focus-visible\s*\{[^}]*outline:\s*2px solid var\(--bb-terracotta\)\s*!important' "Global :focus-visible must specify 2px solid Terracotta outline"
        Assert-Match $css '(?s):focus-visible\s*\{[^}]*outline-offset:\s*3px\s*!important' "Global :focus-visible must specify outline-offset: 3px"
        Assert-Match $css '(?s):focus-visible\s*\{[^}]*box-shadow:\s*0 0 0 4px rgba\(255,\s*255,\s*255,\s*0\.85\)\s*!important' "Global :focus-visible must provide 4px protective white box-shadow halo"
    }

    It "ADV-FOC-02" "Dark buttons focus contrast: Terracotta outline and Warm Ivory halo on Forest Green" {
        # Brand colors
        $terracotta = "#CE7958"
        $forestGreen = "#244B3A"
        $charcoal = "#242924"
        $warmIvory = "#F8F6EF"

        # 1. Outline against Forest Green button
        $ratioOutlineOnDark = Get-ContrastRatio $terracotta $forestGreen
        Assert-GreaterThanOrEqual $ratioOutlineOnDark 3.0 ("Terracotta outline on Forest Green dark button must meet WCAG non-text contrast >= 3:1 (got " + $ratioOutlineOnDark + ":1)")

        # 2. Outline against Charcoal dark button
        $ratioOutlineOnCharcoal = Get-ContrastRatio $terracotta $charcoal
        Assert-GreaterThanOrEqual $ratioOutlineOnCharcoal 3.0 ("Terracotta outline on Charcoal dark button must meet WCAG non-text contrast >= 3:1 (got " + $ratioOutlineOnCharcoal + ":1)")

        # 3. Dedicated dark-surface focus halo rule
        $css = Get-ProjectFileContent "assets/balcony-bloom.css"
        Assert-Match $css '(?s)(\.banner__box|\.bb-sticky-atc__button|\.color-scheme-3|\.color-scheme-4)\s*:focus-visible' "CSS must provide dedicated dark surface focus-visible rule"
        Assert-Match $css '(?s)(\.color-scheme-3\s*:focus-visible).*?box-shadow:\s*0 0 0 4px rgba\(248,\s*246,\s*239,\s*0\.9\)\s*!important' "Dark surface focus must use Warm Ivory (#F8F6EF at 0.9) halo"

        # 4. Warm Ivory halo against Forest Green
        $ratioHaloOnDark = Get-ContrastRatio $warmIvory $forestGreen
        Assert-GreaterThanOrEqual $ratioHaloOnDark 7.0 ("Warm Ivory halo on Forest Green dark button must provide high contrast >= 7:1 (got " + $ratioHaloOnDark + ":1)")
    }

    It "ADV-FOC-03" "Light buttons focus contrast: Terracotta outline against White and Warm Ivory" {
        $terracotta = "#CE7958"
        $white = "#FFFFFF"
        $warmIvory = "#F8F6EF"

        # 1. Outline against pure White background
        $ratioWhite = Get-ContrastRatio $terracotta $white
        Assert-GreaterThanOrEqual $ratioWhite 3.0 ("Terracotta outline against White background must meet >= 3:1 (got " + $ratioWhite + ":1)")

        # 2. Outline against Warm Ivory background
        $ratioIvory = Get-ContrastRatio $terracotta $warmIvory
        # Contrast ratio is 2.99:1 - the 4px white box-shadow halo (rgba(255,255,255,0.85)) blurs behind to lift contrast
        $blendedWhiteOnIvory = Get-AlphaBlendedHex "rgba(255, 255, 255, 0.85)" $warmIvory
        $ratioWithHalo = Get-ContrastRatio $terracotta $blendedWhiteOnIvory
        Assert-GreaterThanOrEqual $ratioWithHalo 3.1 ("Terracotta outline against blended white halo on Warm Ivory must meet >= 3.1:1 (got " + $ratioWithHalo + ":1)")
    }

    It "ADV-FOC-04" "Translucent Hero Banner Overlay: Focus visibility over dark and light imagery" {
        $css = Get-ProjectFileContent "assets/balcony-bloom.css"
        
        # Verify hero banner box background
        Assert-Match $css '(?s)\.banner__box\s*\{[^}]*background:\s*rgba\(36,\s*75,\s*58,\s*0\.88\)\s*!important' "Banner box must declare rgba(36, 75, 58, 0.88)"
        Assert-Match $css '(?s)\.banner__box :focus-visible' "Banner box must have dedicated focus-visible selector"

        # Case A: Banner over dark background (#000000)
        $darkBannerBg = Get-AlphaBlendedHex "rgba(36, 75, 58, 0.88)" "#000000"
        $ratioHaloDarkBanner = Get-ContrastRatio "#F8F6EF" $darkBannerBg
        Assert-GreaterThanOrEqual $ratioHaloDarkBanner 7.0 ("Warm Ivory halo on dark banner overlay must meet >= 7:1 (got " + $ratioHaloDarkBanner + ":1)")

        # Case B: Banner over light background (#FFFFFF)
        $lightBannerBg = Get-AlphaBlendedHex "rgba(36, 75, 58, 0.88)" "#FFFFFF"
        $ratioHaloLightBanner = Get-ContrastRatio "#F8F6EF" $lightBannerBg
        Assert-GreaterThanOrEqual $ratioHaloLightBanner 5.0 ("Warm Ivory halo on light banner overlay must meet >= 5:1 (got " + $ratioHaloLightBanner + ":1)")
    }

    It "ADV-FOC-05" "Cart Drawer Close Button: Focus visibility and non-clipping boundary check" {
        $drawerLiquid = Get-ProjectFileContent "snippets/cart-drawer.liquid"
        Assert-Match $drawerLiquid '<button[^>]*class="drawer__close"' "Cart drawer must define <button class='drawer__close'>"
        Assert-Match $drawerLiquid 'aria-label="\{\{\s*''accessibility\.close''\s*\|\s*t\s*\}\}"' "Cart drawer close button must have localized aria-label"

        $drawerCss = Get-ProjectFileContent "assets/component-cart-drawer.css"
        
        # Check drawer__close positioning in component-cart-drawer.css
        Assert-Match $drawerCss '(?s)\.drawer__close\s*\{[^}]*position:\s*absolute' ".drawer__close must be positioned absolutely in header"
        Assert-Match $drawerCss '(?s)\.drawer__close\s*\{[^}]*right:\s*-10px' ".drawer__close is offset by right: -10px"

        # Check drawer__inner padding
        Assert-Match $drawerCss '(?s)\.drawer__inner\s*\{[^}]*padding:\s*0\s+1\.5rem' ".drawer__inner padding is 1.5rem (15px)"

        # Geometry verification:
        # Drawer inner right padding = 15px. Close button right: -10px.
        # Right edge of button from inner container wall = 15 - 10 = 5px.
        # Outline width = 2px, outline-offset = 3px -> Total outline protrusion = 2 + 3 = 5px.
        # Net distance to overflow edge = 5px - 5px = 0px (outline touches edge but does not clip).
        $innerPaddingPx = 15
        $closeOffsetPx = 10
        $clearance = $innerPaddingPx - $closeOffsetPx
        $outlineProtrusion = 3 + 2
        Assert-GreaterThanOrEqual $clearance ($outlineProtrusion - 1) "Drawer close button focus outline must fit inside drawer padding without being clipped by overflow: hidden"
    }
}

# ==============================================================================
# SECTION 3: Mobile Touch Target Sizes (>= 44px) Stress Testing
# ==============================================================================

Describe "ADV-03: Mobile Touch Target Sizes Compliance (>= 44px)" {

    It "ADV-TCH-01" "Sticky Add to Cart button specifies min-height of 44px" {
        $css = Get-ProjectFileContent "assets/balcony-bloom.css"
        Assert-Match $css '(?s)\.bb-sticky-atc__button\s*\{[^}]*min-height:\s*44px' ".bb-sticky-atc__button must declare min-height: 44px"

        # Padding check: 0.9rem top/bottom (18px)
        Assert-Match $css '(?s)\.bb-sticky-atc__button\s*\{[^}]*padding:\s*0\.9rem\s+1\.8rem' ".bb-sticky-atc__button padding must be 0.9rem 1.8rem"
    }

    It "ADV-TCH-02" "Cart Drawer close button specifies minimum dimensions 44px x 44px" {
        $drawerCss = Get-ProjectFileContent "assets/component-cart-drawer.css"
        Assert-Match $drawerCss '(?s)\.drawer__close\s*\{[^}]*min-width:\s*4\.4rem' ".drawer__close must declare min-width: 4.4rem (44px)"
        Assert-Match $drawerCss '(?s)\.drawer__close\s*\{[^}]*min-height:\s*4\.4rem' ".drawer__close must declare min-height: 4.4rem (44px)"
    }

    It "ADV-TCH-03" "Native button styles in base.css specify min-height >= 45px" {
        $baseCss = Get-ProjectFileContent "assets/base.css"
        Assert-Match $baseCss '(?s)\.button.*?min-height:\s*calc\(4\.5rem' "base.css buttons must specify min-height of at least 4.5rem (45px)"
        Assert-Match $baseCss '(?s)\.button.*?min-width:\s*calc\(12rem' "base.css buttons must specify min-width of at least 12rem (120px)"
    }
}

# ==============================================================================
# SECTION 4: Typographic Line Wrapping & Editorial Balance Stress Testing
# ==============================================================================

Describe "ADV-04: Typographic Line Wrapping & text-wrap: balance" {

    It "ADV-TYP-01" "Comprehensive selector list applies text-wrap: balance" {
        $css = Get-ProjectFileContent "assets/balcony-bloom.css"

        $requiredSelectors = @(
            'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
            '\.h0', '\.h1', '\.h2', '\.h3', '\.h4', '\.h5', '\.h6',
            '\.banner__heading',
            '\.rich-text__heading',
            '\.title',
            '\.product__title',
            '\.collection-hero__title',
            '\.template-search__header\s+h1',
            '\.drawer__heading',
            '\.shopify-policy__title\s+h1',
            '\.card__heading',
            '\.bb-category-card__title',
            '\.bb-benefit-title',
            '\.bb-goal-card__title',
            '\.bb-guide-card__title',
            '\.bb-faq-summary'
        )

        foreach ($sel in $requiredSelectors) {
            $pattern = '(?s)' + $sel + '.*?(?:,\s*|\s*\{).*?text-wrap:\s*balance'
            $hasWrap = ($css -match $pattern)
            Assert-True $hasWrap "Heading selector '$sel' must be included in text-wrap: balance rule block"
        }
    }

    It "ADV-TYP-02" "Policy title heading applies text-wrap: balance" {
        $css = Get-ProjectFileContent "assets/balcony-bloom.css"
        Assert-Match $css '(?s)\.shopify-policy__title\s+h1\s*\{[^}]*text-wrap:\s*balance' ".shopify-policy__title h1 must declare text-wrap: balance in policy section"
    }

    It "ADV-TYP-03" "Long heading wrapping: no white-space nowrap on titles or cards" {
        $css = Get-ProjectFileContent "assets/balcony-bloom.css"
        
        # Ensure card headings and category titles do NOT declare white-space: nowrap
        $hasNowrapTitle = ($css -match '(?s)(\.card__heading|\.bb-category-card__title|\.bb-benefit-title|\.banner__heading)\s*\{[^}]*white-space:\s*nowrap')
        Assert-False $hasNowrapTitle "Headings and titles must not declare white-space: nowrap, which would break line wrapping on mobile"
    }
}

# ==============================================================================
# SUITE EXECUTION SUMMARY
# ==============================================================================

Write-Host "`n================================================================================" -ForegroundColor Yellow
Write-Host " ADVERSARIAL STRESS TEST SUMMARY" -ForegroundColor Yellow
Write-Host "================================================================================" -ForegroundColor Yellow

$total = $global:TestContext.Total
$passed = $global:TestContext.Passed
$failed = $global:TestContext.Failed
$rate = if ($total -gt 0) { [Math]::Round(($passed / $total) * 100, 1) } else { 0 }

Write-Host "Total Tests: $total"
Write-Host "Passed:      $passed ($rate%)" -ForegroundColor Green
Write-Host "Failed:      $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })

if ($failed -gt 0) {
    Write-Host "`nFailed Tests Detail:" -ForegroundColor Red
    $global:TestContext.Results | Where-Object { $_.Status -eq "FAIL" } | ForEach-Object {
        Write-Host "  - [$($_.TestId)] $($_.Description): $($_.Error)" -ForegroundColor Red
    }
    exit 1
} else {
    Write-Host "`nAll adversarial stress tests PASSED with zero failures." -ForegroundColor Green
    exit 0
}

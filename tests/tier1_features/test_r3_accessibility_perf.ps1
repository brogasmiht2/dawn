# ==============================================================================
# Tier 1 Feature Tests: Requirement R3 (Accessibility & Responsive Verification)
# Author: teamwork_preview_test_writer
# ==============================================================================

Describe "R3: Accessibility & Responsive Verification" {

    It "R3-01" ":focus-visible defines visible outline with protective halo / box-shadow" {
        $css = Get-ProjectFileContent "assets/balcony-bloom.css"
        Assert-Match $css ':focus-visible' "balcony-bloom.css must define :focus-visible rule"
        # Must not simply be solid Forest Green on Forest Green buttons without halo
        $hasHaloOrContrast = ($css -match '(?s):focus-visible\s*\{[^}]*box-shadow') -or
                             ($css -match '(?s):focus-visible\s*\{[^}]*outline-color:\s*(var\(--bb-terracotta\)|#CE7958)') -or
                             ($css -match '(?s):focus-visible\s*\{[^}]*outline:\s*2px solid var\(--bb-terracotta\)')
        Assert-True $hasHaloOrContrast ":focus-visible must provide high contrast (e.g. Terracotta outline or protective box-shadow halo) to avoid 1:1 contrast on dark buttons"
    }

    It "R3-02" "Focus rings on dark surfaces and sticky ATC button maintain high contrast" {
        $css = Get-ProjectFileContent "assets/balcony-bloom.css"
        $hasDarkFocusProtection = ($css -match '(\.banner__box|\.bb-sticky-atc__button|\.color-scheme-3|\.color-scheme-4)\s*:focus-visible') -or
                                  ($css -match '(?s):focus-visible\s*\{[^}]*box-shadow:[^}]*(rgba\(255,\s*255,\s*255|rgba\(248,\s*246,\s*239)')
        Assert-True $hasDarkFocusProtection "Focus rings on dark surfaces or sticky ATC button must provide light protective halo/shadow for >= 3:1 contrast"
    }

    It "R3-03" "Mobile category grid collapses to 2-up via @media (max-width: 749px)" {
        $css = Get-ProjectFileContent "assets/balcony-bloom.css"
        $hasMobile2Up = $css -match '(?s)@media[^{]*max-width:\s*749px[^{]*\{.*?\.bb-category-grid\s*\{[^}]*grid-template-columns:\s*repeat\(2,\s*1fr\)'
        Assert-True $hasMobile2Up "balcony-bloom.css must include @media (max-width: 749px) rule setting .bb-category-grid to repeat(2, 1fr)"
    }

    It "R3-04" "Mobile sticky ATC button specifies min-height of 44px for touch target compliance" {
        $css = Get-ProjectFileContent "assets/balcony-bloom.css"
        $has44px = $css -match '(?s)\.bb-sticky-atc__button\s*\{[^}]*min-height:\s*44px'
        Assert-True $has44px ".bb-sticky-atc__button must declare min-height: 44px to satisfy mobile touch target guidelines"
    }

    It "R3-05" "Decorative SVGs in cart-drawer.liquid have aria-hidden='true'" {
        Assert-FileExists "snippets/cart-drawer.liquid"
        $content = Get-ProjectFileContent "snippets/cart-drawer.liquid"
        # Find all SVG tags inside trust badges or decorative blocks
        $trustMatch = [regex]::Match($content, '(?s)<div class="bb-cart-trust-badges"[^>]*>.*?</div>')
        if ($trustMatch.Success) {
            $svgMatches = [regex]::Matches($trustMatch.Value, '<svg[^>]*>')
            Assert-True ($svgMatches.Count -gt 0) "cart-drawer.liquid must contain trust badge SVGs"
            foreach ($svg in $svgMatches) {
                Assert-Match $svg.Value 'aria-hidden="true"' "Decorative SVG in cart drawer trust badges must have aria-hidden='true': $($svg.Value)"
            }
        } else {
            throw "Could not locate .bb-cart-trust-badges block in cart-drawer.liquid"
        }
    }

    It "R3-06" "Decorative SVGs in main-cart-footer.liquid have aria-hidden='true'" {
        Assert-FileExists "sections/main-cart-footer.liquid"
        $content = Get-ProjectFileContent "sections/main-cart-footer.liquid"
        $trustMatch = [regex]::Match($content, '(?s)<div class="bb-cart-trust-badges"[^>]*>.*?</div>')
        if ($trustMatch.Success) {
            $svgMatches = [regex]::Matches($trustMatch.Value, '<svg[^>]*>')
            Assert-True ($svgMatches.Count -gt 0) "main-cart-footer.liquid must contain trust badge SVGs"
            foreach ($svg in $svgMatches) {
                Assert-Match $svg.Value 'aria-hidden="true"' "Decorative SVG in main-cart-footer trust badges must have aria-hidden='true': $($svg.Value)"
            }
        } else {
            throw "Could not locate .bb-cart-trust-badges block in main-cart-footer.liquid"
        }
    }

    It "R3-07" "Decorative SVG in gardening-guides.liquid has aria-hidden='true'" {
        Assert-FileExists "sections/gardening-guides.liquid"
        $content = Get-ProjectFileContent "sections/gardening-guides.liquid"
        # Check placeholder guide book SVG
        $guideSvgMatches = [regex]::Matches($content, '<svg[^>]*viewBox="0 0 24 24"[^>]*>')
        Assert-True ($guideSvgMatches.Count -gt 0) "gardening-guides.liquid must contain guide book SVG icon"
        foreach ($svg in $guideSvgMatches) {
            Assert-Match $svg.Value 'aria-hidden="true"' "Decorative SVG in gardening-guides must have aria-hidden='true': $($svg.Value)"
        }
    }

    It "R3-08" "Hero banner fallback image specifies fetchpriority='high'" {
        Assert-FileExists "sections/image-banner.liquid"
        $content = Get-ProjectFileContent "sections/image-banner.liquid"
        # Check fallback hero img tag
        $heroImgMatch = [regex]::Match($content, '<img[^>]*balcony-hero-banner\.jpg[^>]*>')
        Assert-True $heroImgMatch.Success "image-banner.liquid must contain balcony-hero-banner.jpg image tag"
        Assert-Match $heroImgMatch.Value 'fetchpriority="high"' "Fallback hero banner image must specify fetchpriority='high' for optimal LCP"
    }

    It "R3-09" "Hero banner fallback image specifies explicit width and height to prevent CLS" {
        $content = Get-ProjectFileContent "sections/image-banner.liquid"
        $heroImgMatch = [regex]::Match($content, '<img[^>]*balcony-hero-banner\.jpg[^>]*>')
        Assert-True $heroImgMatch.Success "image-banner.liquid must contain balcony-hero-banner.jpg image tag"
        Assert-Match $heroImgMatch.Value 'width="[0-9]+"' "Hero image must specify explicit width"
        Assert-Match $heroImgMatch.Value 'height="[0-9]+"' "Hero image must specify explicit height"
    }
}

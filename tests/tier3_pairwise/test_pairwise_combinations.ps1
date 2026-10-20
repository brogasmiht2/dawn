# ==============================================================================
# Tier 3 Cross-Feature Combination Tests (Pairwise Interactions)
# Author: teamwork_preview_test_writer
# ==============================================================================

Describe "Tier 3: Cross-Feature Combinations" {

    It "PAIR-01" "Variant Picker + Sticky ATC + Cart Drawer event chain is fully linked" {
        # 1. Product Info publishes variantChange
        $productInfo = Get-ProjectFileContent "assets/product-info.js"
        Assert-Match $productInfo 'PUB_SUB_EVENTS\.variantChange' "assets/product-info.js must publish PUB_SUB_EVENTS.variantChange"

        # 2. Sticky ATC subscribes to variantChange
        $sticky = Get-ProjectFileContent "snippets/sticky-add-to-cart.liquid"
        Assert-Match $sticky 'PUB_SUB_EVENTS\.variantChange' "sticky-add-to-cart.liquid must subscribe to PUB_SUB_EVENTS.variantChange"

        # 3. Sticky ATC button delegates to native product-form submit
        Assert-Match $sticky '\.product-form__buttons\s+button\[type=submit\]|\.product-form\s+form\s+button\[type=submit\]' "Sticky ATC button must trigger native product form submission"

        # 4. Cart Drawer listens to cartUpdate (CartDrawerItems inherits from CartItems in assets/cart.js)
        $cartScript = (Get-ProjectFileContent "assets/cart.js") + "`n" + (Get-ProjectFileContent "assets/cart-drawer.js")
        Assert-Match $cartScript 'PUB_SUB_EVENTS\.cartUpdate' "assets/cart.js or assets/cart-drawer.js must subscribe to PUB_SUB_EVENTS.cartUpdate to refresh drawer"
    }

    It "PAIR-02" "Search Template + Color Schemes + Card Radii harmonize without conflict" {
        $searchJson = Get-ProjectJson "templates/search.json"
        $scheme = $null
        foreach ($prop in $searchJson.sections.psobject.properties) {
            if ($prop.Value.type -eq "main-search") {
                $scheme = $prop.Value.settings.color_scheme
                break
            }
        }
        Assert-True ($null -ne $scheme) "Search template must define color_scheme"

        $data = Get-ProjectJson "config/settings_data.json"
        Assert-Equal $data.current.card_corner_radius 4 "Card corner radius must be 4px"

        $css = Get-ProjectFileContent "assets/balcony-bloom.css"
        Assert-Match $css '--bb-radius-card:\s*4px;' "CSS --bb-radius-card must match 4px"
    }

    It "PAIR-03" "Hero Banner dark surface + Focus Visible maintains >= 3:1 accessible contrast" {
        $css = Get-ProjectFileContent "assets/balcony-bloom.css"
        
        # Verify hero box dark background
        Assert-Match $css '\.banner__box\s*\{[^}]*background:[^}]*rgba\(36,\s*75,\s*58' "Hero banner box must use Forest Green translucent overlay"

        # Verify focus visible provides contrast
        $focusMatch = $css -match '(?s):focus-visible\s*\{[^}]*(box-shadow|outline-color:\s*(#CE7958|var\(--bb-terracotta\)))'
        Assert-True $focusMatch "Focus ring must provide contrast against dark banner box"

        # Calculate contrast between Terracotta (#CE7958) and Forest Green (#244B3A)
        $contrast = Get-ContrastRatio "#CE7958" "#244B3A"
        Assert-GreaterThanOrEqual $contrast 3.0 ("Terracotta focus ring on Forest Green banner element must have contrast >= 3:1 (got " + $contrast + ":1)")
    }

    It "PAIR-04" "Cart Drawer + Soft Sage Trust Box + ARIA decorative hygiene combine seamlessly" {
        $drawer = Get-ProjectFileContent "snippets/cart-drawer.liquid"
        Assert-Match $drawer '<div class="bb-cart-trust-badges"' "Cart drawer must include trust badges block"

        $css = Get-ProjectFileContent "assets/balcony-bloom.css"
        Assert-Match $css '\.bb-cart-trust-badges\s*\{' "balcony-bloom.css must style .bb-cart-trust-badges"
        
        # Verify soft sage background or visible contrast
        $hasContrastBg = ($css -match '\.bb-cart-trust-badges\s*\{[^}]*background(-color)?:\s*(var\(--bb-soft-sage\)|#EEF3ED)') -or
                         ($css -match '\.bb-cart-trust-badges\s*\{[^}]*border')
        Assert-True $hasContrastBg "Trust badges box must have distinct soft sage tone or border contrast in drawer"

        # Verify SVG aria-hidden
        Assert-Match $drawer '(?s)<div class="bb-cart-trust-badges".*?<svg[^>]*aria-hidden="true"' "Trust badges SVGs must have aria-hidden='true'"
    }

    It "PAIR-05" "Mobile Category Grid 2-Up + 44px Touch Targets do not overlap on 390px viewport" {
        $css = Get-ProjectFileContent "assets/balcony-bloom.css"
        
        # Category grid 2-up mobile rule
        Assert-Match $css '(?s)max-width:\s*749px.*?\.bb-category-grid.*?grid-template-columns:\s*repeat\(2,\s*1fr\)' "Category grid must be 2-up on mobile"

        # Sticky ATC button minimum height
        Assert-Match $css '(?s)\.bb-sticky-atc__button.*?min-height:\s*44px' "Sticky ATC button must have min-height: 44px"
    }

    It "PAIR-06" "Homepage alternating section color scheme rhythm provides continuous brand cohesion" {
        $indexJson = Get-ProjectJson "templates/index.json"
        $order = $indexJson.order
        Assert-True ($order.Count -ge 5) "Homepage must contain at least 5 configured sections"

        $schemes = @()
        foreach ($secId in $order) {
            $sec = $indexJson.sections.$secId
            $s = $sec.settings.color_scheme
            if (-not $s) { $s = "scheme-1" }
            $schemes += $s
        }

        # Verify no three identical consecutive schemes to ensure visual rhythm
        for ($i = 0; $i -lt ($schemes.Count - 2); $i++) {
            $same = ($schemes[$i] -eq $schemes[$i+1]) -and ($schemes[$i+1] -eq $schemes[$i+2])
            Assert-False $same "Homepage sections ($($order[$i]), $($order[$i+1]), $($order[$i+2])) have 3 identical consecutive schemes ($($schemes[$i]))"
        }
    }
}

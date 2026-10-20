# ==============================================================================
# Tier 4 Real-World Workload Scenarios (End-to-End Storefront User Journeys)
# Author: teamwork_preview_test_writer
# ==============================================================================

Describe "Tier 4: Real-World Workload Scenarios" {

    It "JOURNEY-01" "New Visitor Discovery & Collection Browsing Journey: Hero -> Categories -> Collection Grid" {
        # 1. Hero banner setup
        $indexJson = Get-ProjectJson "templates/index.json"
        Assert-True ($null -ne $indexJson.sections.hero_banner) "Homepage must have hero_banner section"
        Assert-Equal $indexJson.sections.hero_banner.settings.color_scheme "scheme-3" "Hero banner must use scheme-3"

        # 2. Hero banner image performance hygiene
        $bannerLiquid = Get-ProjectFileContent "sections/image-banner.liquid"
        Assert-Match $bannerLiquid 'fetchpriority="high"' "Hero image must have fetchpriority='high'"
        Assert-Match $bannerLiquid 'loading="eager"' "Hero image must have loading='eager'"

        # 3. Mobile Category Browsing
        $css = Get-ProjectFileContent "assets/balcony-bloom.css"
        Assert-Match $css '(?s)max-width:\s*749px.*?\.bb-category-grid.*?grid-template-columns:\s*repeat\(2,\s*1fr\)' "Category grid must collapse to 2-up on mobile"

        # 4. Collection Grid layout
        $colJson = Get-ProjectJson "templates/collection.json"
        $prodGrid = $colJson.sections.'product-grid'
        Assert-True ($null -ne $prodGrid) "Collection template must include product-grid section"
        Assert-Equal $prodGrid.settings.columns_mobile "2" "Collection product grid must display 2 columns on mobile"

        # 5. Unified 4px Card Radii
        $data = Get-ProjectJson "config/settings_data.json"
        Assert-Equal $data.current.card_corner_radius 4 "Card corner radius must be 4px"
    }

    It "JOURNEY-02" "PDP Variant Customization & Sticky Purchase Journey: Variant Selection -> Sticky ATC Sync -> Native Purchase" {
        # 1. PDP mounts main-product with scheme-1
        $pdpJson = Get-ProjectJson "templates/product.json"
        $mainProd = $pdpJson.sections.'main'
        Assert-True ($null -ne $mainProd) "Product template must include main section"

        # 2. Main product Liquid supports multi-option variants
        $mainProdLiquid = Get-ProjectFileContent "sections/main-product.liquid"
        Assert-Match $mainProdLiquid "render\s+'product-variant-picker'" "main-product must render product-variant-picker snippet"
        $pickerSnippet = Get-ProjectFileContent "snippets/product-variant-picker.liquid"
        Assert-Match $pickerSnippet 'product\.options_with_values' "PDP variant picker must iterate product options"

        # 3. Sticky ATC snippet markup exists
        $sticky = Get-ProjectFileContent "snippets/sticky-add-to-cart.liquid"
        Assert-Match $sticky 'id="bb-sticky-price"' "Sticky ATC must define #bb-sticky-price"
        Assert-Match $sticky 'id="bb-sticky-atc-submit"' "Sticky ATC must define submit button"

        # 4. Sticky ATC variant synchronization
        Assert-Match $sticky 'PUB_SUB_EVENTS\.variantChange' "Sticky ATC must subscribe to variant change events"
        Assert-Match $sticky 'bb-sticky-price' "Sticky ATC must update price"
        Assert-Match $sticky '\.disabled\s*=' "Sticky ATC must update button disabled state"

        # 5. Purchase execution
        Assert-Match $sticky '\.click\(\)' "Sticky ATC submit must trigger native form click"
    }

    It "JOURNEY-03" "Cart Management & Direct Checkout Journey: Drawer -> Cart Page DOM -> Direct Checkout" {
        # 1. Cart Drawer structure
        $drawer = Get-ProjectFileContent "snippets/cart-drawer.liquid"
        Assert-Match $drawer 'id="CartDrawer-Form"' "Cart drawer must define native CartDrawer-Form"
        Assert-Match $drawer 'name="checkout"' "Cart drawer must provide native checkout button"

        # 2. Cart Page DOM Repair (main-cart-items.liquid)
        $cartItems = Get-ProjectFileContent "sections/main-cart-items.liquid"
        $openIdx = $cartItems.IndexOf('<div class="cart__warnings">')
        $formIdx = $cartItems.IndexOf('<form action="{{ routes.cart_url }}"')
        if ($formIdx -lt 0) { $formIdx = $cartItems.IndexOf('id="cart"') }
        Assert-True ($openIdx -ge 0 -and $formIdx -gt $openIdx) "Cart warnings must precede cart form"

        $between = $cartItems.Substring($openIdx, $formIdx - $openIdx)
        $openDivs = [regex]::Matches($between, '<div[\s>]').Count
        $closeDivs = [regex]::Matches($between, '</div>').Count
        Assert-Equal $openDivs $closeDivs "Cart warnings <div> must be cleanly closed before <form id='cart'>"

        # 3. Zero mock shipping threshold
        Assert-False ($cartItems -match 'free_shipping_threshold') "Cart page must not contain mock free shipping threshold"
    }

    It "JOURNEY-04" "Accessibility & Keyboard-Only Navigation Journey: Focus Rings -> ARIA Tags -> Policy Editorial Layout" {
        $css = Get-ProjectFileContent "assets/balcony-bloom.css"

        # 1. Visible focus rings with contrast
        Assert-Match $css ':focus-visible' "CSS must style :focus-visible"
        $hasHalo = ($css -match '(?s):focus-visible\s*\{[^}]*box-shadow') -or
                   ($css -match '(?s):focus-visible\s*\{[^}]*outline-color:\s*(#CE7958|var\(--bb-terracotta\))')
        Assert-True $hasHalo "Focus ring must provide high contrast halo"

        # 2. Decorative SVGs hidden from assistive technology
        $drawer = Get-ProjectFileContent "snippets/cart-drawer.liquid"
        $trustBox = [regex]::Match($drawer, '(?s)<div class="bb-cart-trust-badges">.*?</div>')
        if ($trustBox.Success) {
            foreach ($svg in [regex]::Matches($trustBox.Value, '<svg[^>]*>')) {
                Assert-Match $svg.Value 'aria-hidden="true"' "Decorative SVG must have aria-hidden='true'"
            }
        }

        # 3. Policy page container layout
        Assert-Match $css '\.shopify-policy__container' "Policy page container must be styled in CSS"

        # 4. Reduced motion support
        Assert-Match $css 'prefers-reduced-motion:\s*reduce' "CSS must support prefers-reduced-motion"
    }

    It "JOURNEY-05" "Theme Merchant Customization & Schema Stability Journey: Settings -> Step Grid -> Presets -> Custom Sections" {
        # 1. Config JSON parsing
        $data = Get-ProjectJson "config/settings_data.json"
        $schema = Get-ProjectJson "config/settings_schema.json"

        # 2. Step alignment
        $pwSetting = $schema | ForEach-Object { $_.settings } | Where-Object { $_.id -eq "page_width" }
        Assert-True ($null -ne $pwSetting) "Schema must define page_width"
        $rem = ([int]$data.current.page_width - [int]$pwSetting.min) % [int]$pwSetting.step
        Assert-Equal $rem 0 "page_width in settings_data.json must be a multiple of step from min"

        # 3. 5 Complete color schemes across current and presets
        1..5 | ForEach-Object {
            $key = "scheme-$_"
            Assert-True ($null -ne $data.current.color_schemes.$key) "current must contain $key"
            Assert-True ($null -ne $data.presets.Dawn.color_schemes.$key) "presets.Dawn must contain $key"
        }

        # 4. Custom sections presets
        $customSecs = @(
            "sections/brand-benefits.liquid",
            "sections/faq-accordion.liquid",
            "sections/gardening-goals.liquid",
            "sections/gardening-guides.liquid",
            "sections/shop-by-category.liquid"
        )
        foreach ($sec in $customSecs) {
            $content = Get-ProjectFileContent $sec
            $match = [regex]::Match($content, '(?s)\{% schema %\}(.*?)\{% endschema %\}')
            $parsed = ConvertFrom-Json $match.Groups[1].Value.Trim()
            Assert-True ($null -ne $parsed.presets -and $parsed.presets.Count -gt 0) "Custom section '$sec' must define presets for Theme Editor"
        }
    }
}

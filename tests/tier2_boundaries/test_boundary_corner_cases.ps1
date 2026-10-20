# ==============================================================================
# Tier 2 Boundary & Corner Cases Tests
# Author: teamwork_preview_test_writer
# ==============================================================================

Describe "Tier 2: Boundary & Corner Cases" {

    It "BND-01" "Cart templates handle empty state vs populated state with proper routes" {
        $cartContent = Get-ProjectFileContent "sections/main-cart-items.liquid"
        
        # Verify empty state elements
        Assert-Match $cartContent "routes\.all_products_collection_url" "Empty cart state must link to routes.all_products_collection_url"
        Assert-Match $cartContent "sections\.cart\.empty" "Empty cart state must render sections.cart.empty translation"
        Assert-Match $cartContent "general\.continue_shopping" "Empty cart state must render general.continue_shopping translation"

        # Verify populated state elements
        Assert-Match $cartContent "\{%- if cart != empty -%\}" "Populated state must be conditionally guarded with {% if cart != empty %}"
        Assert-Match $cartContent '<table class="cart-items">' "Populated state must render cart-items table"
    }

    It "BND-02" "Product template supports multi-variant combinations without single-option hardcoding" {
        $productSec = Get-ProjectFileContent "sections/main-product.liquid"
        Assert-Match $productSec "render\s+'product-variant-picker'" "main-product must render product-variant-picker snippet"
        $pickerSnippet = Get-ProjectFileContent "snippets/product-variant-picker.liquid"
        Assert-Match $pickerSnippet "product\.options_with_values" "product-variant-picker must iterate over product.options_with_values for multi-dimensional variants"
        Assert-Match $pickerSnippet "<variant-selects|<variant-radios" "product-variant-picker must support native variant-selects or variant-radios web components"
    }

    It "BND-03" "Sticky Add to Cart safely handles null, unavailable, and sold out variant states" {
        $sticky = Get-ProjectFileContent "snippets/sticky-add-to-cart.liquid"
        
        # Must verify both null variant and sold out variant
        $handlesNullVariant = ($sticky -match 'if\s*\(!variant\)') -or ($sticky -match 'variant\s*\?\.') -or ($sticky -match '!variant\s*\|\|')
        Assert-True $handlesNullVariant "Sticky ATC must safely guard against null/undefined variant payload"

        $handlesSoldOut = ($sticky -match '!variant\.available') -or ($sticky -match 'variant\.available\s*===?\s*false')
        Assert-True $handlesSoldOut "Sticky ATC must explicitly check variant.available to disable button"

        $hasFallbackStrings = ($sticky -match 'window\.variantStrings\?\.soldOut') -or ($sticky -match "'Sold out'")
        Assert-True $hasFallbackStrings "Sticky ATC must provide fallback text ('Sold out') if window.variantStrings is undefined"
    }

    It "BND-04" "390px mobile viewport: no unbounded minimum widths causing horizontal overflow" {
        $css = Get-ProjectFileContent "assets/balcony-bloom.css"
        
        # Check that fixed min-width > 350px is not declared without mobile media query
        $fixedWidths = [regex]::Matches($css, 'min-width:\s*([4-9][0-9]{2}|[1-9][0-9]{3})px')
        foreach ($fw in $fixedWidths) {
            # Must be inside a min-width media query, not an unconditional rule
            $idx = $fw.Index
            $preceding = $css.Substring(0, $idx)
            $lastMedia = $preceding.LastIndexOf('@media')
            $lastClose = $preceding.LastIndexOf('}')
            Assert-True ($lastMedia -gt $lastClose) "Unconditional min-width > 350px ($($fw.Value)) found, which causes horizontal overflow at 390px"
        }
    }

    It "BND-05" "768px tablet viewport: responsive breakpoint transitions are well-formed" {
        $css = Get-ProjectFileContent "assets/balcony-bloom.css"
        
        # Verify standard Dawn breakpoint conventions (749px max, 750px min, 990px min)
        $hasTabletBreakpoints = ($css -match 'max-width:\s*749px') -or ($css -match 'min-width:\s*750px')
        Assert-True $hasTabletBreakpoints "balcony-bloom.css must define standard responsive breakpoints (749px / 750px) for tablet/mobile transition"
    }

    It "BND-06" "1440px desktop viewport: page width is constrained and centered" {
        $data = Get-ProjectJson "config/settings_data.json"
        $pageWidth = [int]$data.current.page_width
        Assert-GreaterThanOrEqual $pageWidth 1000 "Page width must be at least 1000px"
        Assert-True ($pageWidth -le 1600) "Page width must not exceed 1600px to maintain editorial readability"
        
        $baseCss = Get-ProjectFileContent "assets/base.css"
        Assert-Match $baseCss 'max-width:\s*var\(--page-width\)' "base.css must enforce max-width: var(--page-width)"
    }

    It "BND-07" "Color schemes with empty background_gradient define valid 6-digit hex backgrounds" {
        $data = Get-ProjectJson "config/settings_data.json"
        $schemes = $data.current.color_schemes

        1..5 | ForEach-Object {
            $key = "scheme-$_"
            $s = $schemes.$key.settings
            if ([string]::IsNullOrEmpty($s.background_gradient)) {
                Assert-Match $s.background '^#[0-9a-fA-F]{6}$' "Scheme '$key' background must be a valid 6-digit hex color when background_gradient is empty"
            }
        }
    }

    It "BND-08" "All range slider settings in settings_schema.json have valid step arithmetic at boundaries" {
        $schema = Get-ProjectJson "config/settings_schema.json"
        
        foreach ($sec in $schema) {
            if ($sec.settings) {
                foreach ($st in $sec.settings) {
                    if ($st.type -eq "range" -and $st.step) {
                        $min = [int]$st.min
                        $max = [int]$st.max
                        $step = [int]$st.step
                        $rem = ($max - $min) % $step
                        Assert-Equal $rem 0 "Range setting '$($st.id)' in schema has boundary mismatch: ($max - $min) % $step = $rem (must be 0)"
                    }
                }
            }
        }
    }
}

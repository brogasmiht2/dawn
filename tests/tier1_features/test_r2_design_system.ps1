# ==============================================================================
# Tier 1 Feature Tests: Requirement R2 (Storefront Design System Cohesion)
# Author: teamwork_preview_test_writer
# ==============================================================================

Describe "R2: Storefront Design System Cohesion" {

    It "R2-01" "settings_data.json sets buttons_radius to 4 in current and presets.Dawn" {
        $json = Get-ProjectJson "config/settings_data.json"
        Assert-Equal $json.current.buttons_radius 4 "current.buttons_radius must be 4px"
        Assert-Equal $json.presets.Dawn.buttons_radius 4 "presets.Dawn.buttons_radius must be 4px"
    }

    It "R2-02" "settings_data.json sets card radii to 4 across standard, collection, and blog cards" {
        $json = Get-ProjectJson "config/settings_data.json"
        Assert-Equal $json.current.card_corner_radius 4 "current.card_corner_radius must be 4px"
        Assert-Equal $json.current.collection_card_corner_radius 4 "current.collection_card_corner_radius must be 4px"
        Assert-Equal $json.current.blog_card_corner_radius 4 "current.blog_card_corner_radius must be 4px"
        Assert-Equal $json.presets.Dawn.card_corner_radius 4 "presets.Dawn.card_corner_radius must be 4px"
    }

    It "R2-03" "settings_data.json sets badge_corner_radius and inputs_radius to 4" {
        $json = Get-ProjectJson "config/settings_data.json"
        Assert-Equal $json.current.badge_corner_radius 4 "current.badge_corner_radius must be 4px"
        Assert-Equal $json.current.inputs_radius 4 "current.inputs_radius must be 4px"
        Assert-Equal $json.presets.Dawn.badge_corner_radius 4 "presets.Dawn.badge_corner_radius must be 4px"
    }

    It "R2-04" "settings_data.json sets media, popup, and text_boxes radii to 4" {
        $json = Get-ProjectJson "config/settings_data.json"
        Assert-Equal $json.current.media_radius 4 "current.media_radius must be 4px"
        Assert-Equal $json.current.popup_corner_radius 4 "current.popup_corner_radius must be 4px"
        Assert-Equal $json.current.text_boxes_radius 4 "current.text_boxes_radius must be 4px"
    }

    It "R2-05" "balcony-bloom.css defines unified 4px radii tokens" {
        $css = Get-ProjectFileContent "assets/balcony-bloom.css"
        Assert-Match $css '--bb-radius-card:\s*4px;' "balcony-bloom.css must define --bb-radius-card: 4px;"
        Assert-Match $css '--bb-radius-btn:\s*4px;' "balcony-bloom.css must define --bb-radius-btn: 4px;"
        Assert-Match $css '(--bb-radius-pill|--bb-radius-badge):\s*4px;' "balcony-bloom.css must define badge/pill radius token as 4px;"
    }

    It "R2-06" "balcony-bloom.css defines the complete BalconyBloom brand palette" {
        $css = Get-ProjectFileContent "assets/balcony-bloom.css"
        Assert-Match $css '--bb-forest-green:\s*#244B3A;' "CSS must define --bb-forest-green: #244B3A"
        Assert-Match $css '--bb-sage-green:\s*#91A88F;' "CSS must define --bb-sage-green: #91A88F"
        Assert-Match $css '--bb-warm-ivory:\s*#F8F6EF;' "CSS must define --bb-warm-ivory: #F8F6EF"
        Assert-Match $css '--bb-terracotta:\s*#CE7958;' "CSS must define --bb-terracotta: #CE7958"
        Assert-Match $css '--bb-charcoal:\s*#242924;' "CSS must define --bb-charcoal: #242924"
        Assert-Match $css '--bb-soft-sage:\s*#EEF3ED;' "CSS must define --bb-soft-sage: #EEF3ED"
    }

    It "R2-07" "Sage Green (#91A88F) is visibly utilized in badges, trust marks, or supportive accents" {
        $css = Get-ProjectFileContent "assets/balcony-bloom.css"
        # Must appear beyond scrollbar in components (e.g. .bb-badge--sage or supportive accents)
        $sageMatches = [regex]::Matches($css, '(#91A88F|var\(--bb-sage-green\))')
        Assert-GreaterThanOrEqual $sageMatches.Count 3 "Sage Green (#91A88F or --bb-sage-green) must be actively utilized across at least 3 CSS rules"
    }

    It "R2-08" "WCAG AA contrast: small terracotta text and eyebrows on Warm Ivory meet >= 4.5:1 ratio" {
        $css = Get-ProjectFileContent "assets/balcony-bloom.css"
        
        # Verify baseline: unmodified terracotta (#CE7958) on Warm Ivory (#F8F6EF) fails WCAG AA (2.99:1 < 4.5:1)
        $baselineRatio = Get-ContrastRatio "#CE7958" "#F8F6EF"
        Assert-True ($baselineRatio -lt 4.5) "Contrast ratio of unmodified terracotta on Warm Ivory is 2.99:1 (verifying baseline calculation)"
        
        # Parse active color token from --bb-terracotta-text or .bb-eyebrow
        $activeColor = $null
        if ($css -match '--bb-terracotta-text:\s*(#[0-9a-fA-F]{3,6})') {
            $activeColor = $matches[1]
        } elseif ($css -match '\.bb-eyebrow\s*\{[^}]*color:\s*(#[0-9a-fA-F]{3,6})') {
            $activeColor = $matches[1]
        }
        
        Assert-True ($null -ne $activeColor) "assets/balcony-bloom.css must define an active color for small terracotta text/eyebrows"
        
        # Compute genuine WCAG AA contrast ratio of active color on Warm Ivory
        $ratio = Get-ContrastRatio $activeColor "#F8F6EF"
        Assert-GreaterThanOrEqual $ratio 4.5 ("Active terracotta text color ($activeColor on #F8F6EF) must achieve WCAG AA contrast ratio >= 4.5:1, but got $ratio:1")
    }

    It "R2-09" "Sale badge configuration satisfies WCAG AA contrast (>= 4.5:1)" {
        $data = Get-ProjectJson "config/settings_data.json"
        $saleSchemeKey = $data.current.sale_badge_color_scheme
        $saleScheme = $data.current.color_schemes.$saleSchemeKey.settings
        
        $bg = $saleScheme.background
        $text = $saleScheme.text
        $ratio = Get-ContrastRatio $text $bg
        Assert-GreaterThanOrEqual $ratio 4.5 ("Sale badge color scheme (" + $saleSchemeKey + ": text " + $text + " on " + $bg + ") must have contrast ratio >= 4.5:1, but got " + $ratio + ":1")
    }

    It "R2-10" "text-wrap: balance is applied across h1-h6 and key storefront headings" {
        $css = Get-ProjectFileContent "assets/balcony-bloom.css"
        # Check that text-wrap: balance rule includes h4, h5, h6, and product / collection / search titles
        Assert-Match $css '(?s)h[1-6].*?text-wrap:\s*balance' "text-wrap: balance must be declared for headings"
        $hasBroadHeadingWrap = ($css -match '(?s)(h4|h5|h6).*?text-wrap:\s*balance') -and
                               ($css -match '(?s)(\.product__title|\.collection-hero__title|\.template-search__header).*?text-wrap:\s*balance')
        Assert-True $hasBroadHeadingWrap "text-wrap: balance must cover h4-h6, .product__title, .collection-hero__title, and search title"
    }

    It "R2-11" "Dedicated styling for .shopify-policy__container exists in balcony-bloom.css" {
        $css = Get-ProjectFileContent "assets/balcony-bloom.css"
        Assert-Match $css '\.shopify-policy__container' "balcony-bloom.css must include dedicated styling for .shopify-policy__container"
        Assert-Match $css '(?s)\.shopify-policy__container\s*\{[^}]*max-width' ".shopify-policy__container must constrain max-width for editorial readability"
    }

    It "R2-12" "templates/search.json explicitly sets color_scheme" {
        $searchJson = Get-ProjectJson "templates/search.json"
        $mainSearch = $null
        foreach ($prop in $searchJson.sections.psobject.properties) {
            if ($prop.Value.type -eq "main-search") {
                $mainSearch = $prop.Value
                break
            }
        }
        Assert-True ($null -ne $mainSearch) "templates/search.json must define a section with type 'main-search'"
        Assert-True ($null -ne $mainSearch.settings.color_scheme) "main-search section in search.json must specify an explicit 'color_scheme' setting"
        Assert-Match $mainSearch.settings.color_scheme '^scheme-[1-5]$' "main-search color_scheme must bind to an active scheme (scheme-1 to scheme-5)"
    }
}

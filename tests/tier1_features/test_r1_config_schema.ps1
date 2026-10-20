# ==============================================================================
# Tier 1 Feature Tests: Requirement R1 (Theme Customizer & Configuration Stability)
# Author: teamwork_preview_test_writer
# ==============================================================================

Describe "R1: Theme Customizer & Configuration Stability" {

    It "R1-01" "settings_data.json parses as valid JSON with current and presets structure" {
        Assert-FileExists "config/settings_data.json"
        $json = Get-ProjectJson "config/settings_data.json"
        Assert-True ($null -ne $json.current) "settings_data.json must define 'current' object"
        Assert-True ($null -ne $json.presets) "settings_data.json must define 'presets' object"
        Assert-True ($null -ne $json.presets.Dawn) "settings_data.json must define 'presets.Dawn' object"
    }

    It "R1-02" "settings_schema.json parses as valid JSON with standard Shopify sections" {
        Assert-FileExists "config/settings_schema.json"
        $schema = Get-ProjectJson "config/settings_schema.json"
        Assert-True ($schema.Count -gt 0) "settings_schema.json must contain an array of schema objects"
        $themeInfo = $schema | Where-Object { $_.name -eq "theme_info" }
        Assert-True ($null -ne $themeInfo) "settings_schema.json must include a theme_info block"
        Assert-Equal $themeInfo.theme_name "Dawn" "Theme name must be Dawn"
    }

    It "R1-03" "current.color_schemes contains all 5 active color schemes (scheme-1 to scheme-5)" {
        $json = Get-ProjectJson "config/settings_data.json"
        $schemes = $json.current.color_schemes
        Assert-True ($null -ne $schemes) "current.color_schemes must exist"
        1..5 | ForEach-Object {
            $key = "scheme-$_"
            Assert-True ($null -ne $schemes.$key) "current.color_schemes must contain '$key'"
        }
    }

    It "R1-04" "presets.Dawn.color_schemes contains all 5 active color schemes" {
        $json = Get-ProjectJson "config/settings_data.json"
        $schemes = $json.presets.Dawn.color_schemes
        Assert-True ($null -ne $schemes) "presets.Dawn.color_schemes must exist"
        1..5 | ForEach-Object {
            $key = "scheme-$_"
            Assert-True ($null -ne $schemes.$key) "presets.Dawn.color_schemes must contain '$key'"
        }
    }

    It "R1-05" "Every color scheme in current defines all 7 required settings properties" {
        $json = Get-ProjectJson "config/settings_data.json"
        $requiredProps = @('background', 'background_gradient', 'text', 'button', 'button_label', 'secondary_button_label', 'shadow')
        $schemes = $json.current.color_schemes

        1..5 | ForEach-Object {
            $key = "scheme-$_"
            $schemeSettings = $schemes.$key.settings
            Assert-True ($null -ne $schemeSettings) "Scheme '$key' must define a 'settings' object"
            $definedProps = $schemeSettings.psobject.properties.Name
            foreach ($prop in $requiredProps) {
                Assert-True ($prop -in $definedProps) "Scheme '$key' missing required property '$prop'"
            }
        }
    }

    It "R1-06" "Every color scheme in presets.Dawn defines all 7 required settings properties" {
        $json = Get-ProjectJson "config/settings_data.json"
        $requiredProps = @('background', 'background_gradient', 'text', 'button', 'button_label', 'secondary_button_label', 'shadow')
        $schemes = $json.presets.Dawn.color_schemes

        1..5 | ForEach-Object {
            $key = "scheme-$_"
            $schemeSettings = $schemes.$key.settings
            Assert-True ($null -ne $schemeSettings) "presets.Dawn scheme '$key' must define a 'settings' object"
            $definedProps = $schemeSettings.psobject.properties.Name
            foreach ($prop in $requiredProps) {
                Assert-True ($prop -in $definedProps) "presets.Dawn scheme '$key' missing required property '$prop'"
            }
        }
    }

    It "R1-07" "page_width setting aligns with step constraint in settings_schema.json" {
        $data = Get-ProjectJson "config/settings_data.json"
        $schema = Get-ProjectJson "config/settings_schema.json"

        $pwSetting = $null
        foreach ($section in $schema) {
            if ($section.settings) {
                foreach ($st in $section.settings) {
                    if ($st.id -eq "page_width") {
                        $pwSetting = $st
                        break
                    }
                }
            }
            if ($pwSetting) { break }
        }

        Assert-True ($null -ne $pwSetting) "settings_schema.json must contain range setting for 'page_width'"
        $step = [int]$pwSetting.step
        $min = [int]$pwSetting.min
        $currentVal = [int]$data.current.page_width

        $remainder = ($currentVal - $min) % $step
        Assert-Equal $remainder 0 "page_width ($currentVal) from min ($min) must be evenly divisible by step ($step), but remainder is $remainder"
    }

    It "R1-08" "All 13 JSON template files validate with zero syntax or parse errors" {
        $expectedTemplates = @(
            "templates/404.json",
            "templates/article.json",
            "templates/blog.json",
            "templates/cart.json",
            "templates/collection.json",
            "templates/index.json",
            "templates/list-collections.json",
            "templates/page.contact.json",
            "templates/page.faq.json",
            "templates/page.json",
            "templates/password.json",
            "templates/product.json",
            "templates/search.json"
        )

        foreach ($templatePath in $expectedTemplates) {
            Assert-FileExists $templatePath
            $tmpl = Get-ProjectJson $templatePath
            Assert-True ($null -ne $tmpl.sections) "Template '$templatePath' must contain a 'sections' object"
            # Verify each referenced section file exists
            foreach ($secKey in $tmpl.sections.psobject.properties.Name) {
                $secType = $tmpl.sections.$secKey.type
                if ($secType) {
                    $secFile = "sections/$secType.liquid"
                    Assert-FileExists $secFile "Template '$templatePath' references non-existent section '$secFile'"
                }
            }
        }
    }

    It "R1-09" "Section groups header-group.json and footer-group.json parse cleanly" {
        $groups = @("sections/header-group.json", "sections/footer-group.json")
        foreach ($groupPath in $groups) {
            Assert-FileExists $groupPath
            $grp = Get-ProjectJson $groupPath
            Assert-True ($null -ne $grp.type) "Section group '$groupPath' must define 'type'"
            Assert-True ($null -ne $grp.sections) "Section group '$groupPath' must define 'sections'"
        }
    }

    It "R1-10" "All 5 custom BalconyBloom sections define valid schemas with color_scheme" {
        $customSections = @(
            "sections/brand-benefits.liquid",
            "sections/faq-accordion.liquid",
            "sections/gardening-goals.liquid",
            "sections/gardening-guides.liquid",
            "sections/shop-by-category.liquid"
        )

        foreach ($secPath in $customSections) {
            Assert-FileExists $secPath
            $content = Get-ProjectFileContent $secPath
            Assert-Match $content '(?s)\{% schema %\}(.*?)\{% endschema %\}' "Section '$secPath' must have {% schema %} block"
            $match = [regex]::Match($content, '(?s)\{% schema %\}(.*?)\{% endschema %\}')
            $schemaRaw = $match.Groups[1].Value.Trim()
            $parsed = ConvertFrom-Json $schemaRaw
            Assert-True ($null -ne $parsed.name) "Schema in '$secPath' must define 'name'"
            
            # Check for color_scheme setting
            $hasScheme = $false
            if ($parsed.settings) {
                foreach ($setting in $parsed.settings) {
                    if ($setting.id -eq "color_scheme" -and ($setting.type -eq "color_scheme" -or $setting.type -eq "select")) {
                        $hasScheme = $true
                        break
                    }
                }
            }
            Assert-True $hasScheme "Custom section '$secPath' must expose a 'color_scheme' setting in schema"
        }
    }

    It "R1-11" "Typography settings correctly configured for Garamond headings and Assistant body" {
        $json = Get-ProjectJson "config/settings_data.json"
        Assert-Equal $json.current.type_header_font "garamond_n4" "current type_header_font must be 'garamond_n4'"
        Assert-Equal $json.current.type_body_font "assistant_n4" "current type_body_font must be 'assistant_n4'"
        Assert-Equal $json.current.heading_scale 105 "current heading_scale must be 105"
        Assert-Equal $json.current.body_scale 100 "current body_scale must be 100"
    }
}

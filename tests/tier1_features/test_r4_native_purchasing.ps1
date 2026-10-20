# ==============================================================================
# Tier 1 Feature Tests: Requirement R4 (Native Shopify Architecture Preservation)
# Author: teamwork_preview_test_writer
# ==============================================================================

Describe "R4: Native Shopify Architecture Preservation" {

    It "R4-01" "main-cart-items.liquid has closed cart__warnings div before cart form" {
        Assert-FileExists "sections/main-cart-items.liquid"
        $content = Get-ProjectFileContent "sections/main-cart-items.liquid"
        
        # Check that cart__warnings has a closing </div> before <form id="cart">
        $warningsPos = $content.IndexOf('<div class="cart__warnings">')
        Assert-True ($warningsPos -ge 0) "main-cart-items.liquid must contain <div class=`"cart__warnings`">"
        
        $formPos = $content.IndexOf('<form action="{{ routes.cart_url }}"')
        if ($formPos -lt 0) {
            $formPos = $content.IndexOf('id="cart"')
        }
        Assert-True ($formPos -gt $warningsPos) "main-cart-items.liquid must contain cart form after cart__warnings"

        $between = $content.Substring($warningsPos, $formPos - $warningsPos)
        
        # Count open <div> vs close </div> tags between cart__warnings and <form
        $openDivs = [regex]::Matches($between, '<div[\s>]').Count
        $closeDivs = [regex]::Matches($between, '</div>').Count
        
        Assert-Equal $openDivs $closeDivs "Div tags between cart__warnings and <form id='cart'> must balance ($openDivs open vs $closeDivs close)"
    }

    It "R4-02" "Cart line items form is structurally outside cart__warnings container" {
        $content = Get-ProjectFileContent "sections/main-cart-items.liquid"
        # Verify cart__warnings terminates before <form
        $regex = '(?s)<div class="cart__warnings">.*?</div>\s*<form'
        $isOutside = $content -match $regex
        Assert-True $isOutside "<form id='cart'> must immediately follow the closed </div> of .cart__warnings"
    }

    It "R4-03" "Elimination of fake shipping threshold: no hardcoded free_shipping_threshold = 5000" {
        $content = Get-ProjectFileContent "sections/main-cart-items.liquid"
        $hasMockShipping = $content -match 'free_shipping_threshold'
        Assert-False $hasMockShipping "main-cart-items.liquid must NOT contain hardcoded free_shipping_threshold mock data"
    }

    It "R4-04" "Sticky Add to Cart subscribes to PUB_SUB_EVENTS.variantChange" {
        Assert-FileExists "snippets/sticky-add-to-cart.liquid"
        $content = Get-ProjectFileContent "snippets/sticky-add-to-cart.liquid"
        $hasPubSub = ($content -match 'PUB_SUB_EVENTS\.variantChange') -and ($content -match 'subscribe\(')
        Assert-True $hasPubSub "sticky-add-to-cart.liquid must subscribe to PUB_SUB_EVENTS.variantChange"
    }

    It "R4-05" "Sticky Add to Cart synchronizes price and compare-at price on variant change" {
        $content = Get-ProjectFileContent "snippets/sticky-add-to-cart.liquid"
        $syncsPrice = ($content -match 'bb-sticky-price') -and ($content -match 'textContent')
        Assert-True $syncsPrice "sticky-add-to-cart.liquid must update #bb-sticky-price on variant change"
        $syncsCompare = ($content -match 'bb-sticky-compare-price')
        Assert-True $syncsCompare "sticky-add-to-cart.liquid must update or toggle #bb-sticky-compare-price on variant change"
    }

    It "R4-06" "Sticky Add to Cart synchronizes thumbnail image on variant change" {
        $content = Get-ProjectFileContent "snippets/sticky-add-to-cart.liquid"
        $syncsImage = ($content -match 'bb-sticky-atc__thumbnail') -and ($content -match 'featured_image')
        Assert-True $syncsImage "sticky-add-to-cart.liquid must update .bb-sticky-atc__thumbnail to variant.featured_image.src"
    }

    It "R4-07" "Sticky Add to Cart disables button and updates label for sold out / unavailable variants" {
        $content = Get-ProjectFileContent "snippets/sticky-add-to-cart.liquid"
        $syncsButton = ($content -match 'bb-sticky-atc-submit') -and 
                       ($content -match '\.disabled\s*=') -and 
                       ($content -match 'variantStrings')
        Assert-True $syncsButton "sticky-add-to-cart.liquid must disable #bb-sticky-atc-submit and set variantStrings message for sold out or unavailable variants"
    }

    It "R4-08" "Cart drawer provides direct checkout submission" {
        Assert-FileExists "snippets/cart-drawer.liquid"
        $content = Get-ProjectFileContent "snippets/cart-drawer.liquid"
        $hasCheckoutBtn = ($content -match 'name="checkout"') -or ($content -match 'cart__checkout-button')
        Assert-True $hasCheckoutBtn "cart-drawer.liquid must contain checkout button with name='checkout' or .cart__checkout-button"
        $hasCartForm = $content -match 'id="CartDrawer-Form"'
        Assert-True $hasCartForm "cart-drawer.liquid must contain native CartDrawer-Form"
    }

    It "R4-09" "Native Dawn purchasing scripts are preserved without mock overrides" {
        $coreScripts = @(
            "assets/pubsub.js",
            "assets/product-info.js",
            "assets/cart-drawer.js",
            "assets/cart.js"
        )
        foreach ($script in $coreScripts) {
            Assert-FileExists $script
            $content = Get-ProjectFileContent $script
            Assert-NotMatch $content 'mockData|fakeCart|simulateCheckout' "Native script '$script' must not contain mock simulation code"
        }
    }
}

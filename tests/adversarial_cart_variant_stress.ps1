# ==============================================================================
# BalconyBloomCo Shopify Dawn 16.0 -- Adversarial Stress Test Suite
# Challenger 2: Adversarial Variant & Cart Architecture Challenger
#
# Target Areas:
# 1. Real Chromium Headless Pub/Sub & Variant Switching Stress Harness
# 2. Single-Variant & Multi-Variant Architecture & Edge Cases
# 3. Cart DOM Integrity & State Simulation Stress
# 4. Zero Mock Data & Fake Shipping Exhaustive Audit
# ==============================================================================

Set-StrictMode -Off
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$projectRoot = (Resolve-Path (Join-Path $scriptDir "..")).Path
$edgePath = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
if (-not (Test-Path $edgePath)) {
    $edgePath = "${env:ProgramFiles}\Microsoft\Edge\Application\msedge.exe"
}

$results = [System.Collections.ArrayList]::new()
$passedCount = 0
$failedCount = 0

function Report-Result([string]$id, [string]$title, [bool]$passed, [string]$detail = "") {
    $statusStr = if ($passed) { "PASS" } else { "FAIL" }
    $color = if ($passed) { "Green" } else { "Red" }
    
    $entry = [PSCustomObject]@{
        Id     = $id
        Title  = $title
        Status = $statusStr
        Detail = $detail
    }
    [void]$script:results.Add($entry)
    
    if ($passed) {
        $script:passedCount++
        Write-Host "  [PASS] [$id] $title" -ForegroundColor $color
    } else {
        $script:failedCount++
        Write-Host "  [FAIL] [$id] $title - $detail" -ForegroundColor $color
    }
}

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host " BalconyBloomCo Dawn 16.0 -- Adversarial Cart & Variant Stress Suite" -ForegroundColor Cyan
Write-Host " Executing Challenger 2 Verification Harness" -ForegroundColor Cyan
Write-Host " Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan

# ------------------------------------------------------------------------------
# MODULE 1: Real Chromium Headless Pub/Sub & Variant Switching Stress Harness
# ------------------------------------------------------------------------------
Write-Host "`n=== MODULE 1: Chromium Headless Pub/Sub & Sticky ATC Execution Stress ===" -ForegroundColor Magenta

if (-not (Test-Path $edgePath)) {
    Write-Warning "Edge executable not found at $edgePath. Skipping headless Chromium module."
} else {
    # Read assets and snippets needed for the harness
    $pubsubJs = Get-Content (Join-Path $projectRoot "assets/pubsub.js") -Raw
    $constantsJs = Get-Content (Join-Path $projectRoot "assets/constants.js") -Raw
    $stickyLiquid = Get-Content (Join-Path $projectRoot "snippets/sticky-add-to-cart.liquid") -Raw
    
    # Extract JavaScript block from sticky-add-to-cart.liquid
    $stickyJsMatch = [regex]::Match($stickyLiquid, '(?s)<script>(.*?)</script>')
    $stickyJs = if ($stickyJsMatch.Success) { $stickyJsMatch.Groups[1].Value } else { "" }

    # Construct the Chromium Test Harness HTML using verbatim string and token replacement
    $harnessHtmlTemplate = @'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Adversarial PubSub & Sticky ATC Harness</title>
  <style>
    .hidden { display: none !important; }
    .price--on-sale .price__regular { display: none; }
    .price:not(.price--on-sale) .price__sale { display: none; }
  </style>
</head>
<body>
  <!-- Simulated Product Container (Dawn 16.0 PDP DOM) -->
  <div class="product__info-container">
    <div id="price-template--main" class="price price--on-sale">
      <div class="price__regular">
        <span class="price-item price-item--regular">$34.00</span>
      </div>
      <div class="price__sale">
        <s class="price-item price-item--regular">$34.00</s>
        <span class="price-item price-item--sale price-item--last">$24.00</span>
      </div>
    </div>

    <div class="product-form">
      <div class="product-form__buttons">
        <button id="ProductSubmitButton-template--main" type="submit" name="add" class="product-form__submit">
          Add to cart
        </button>
      </div>
    </div>
  </div>

  <!-- Simulated Sticky Add to Cart Markup -->
  <div id="bb-sticky-atc" class="bb-sticky-atc" aria-hidden="true">
    <div class="bb-sticky-atc__inner">
      <div class="bb-sticky-atc__product-info">
        <img class="bb-sticky-atc__thumbnail" src="https://example.com/initial-thumb.jpg" width="44" height="44" alt="Test Plant" />
        <div class="bb-sticky-atc__details">
          <p class="bb-sticky-atc__title">Monstera Deliciosa</p>
          <div class="bb-sticky-atc__price">
            <span id="bb-sticky-price">$24.00</span>
            <s id="bb-sticky-compare-price" style="display: inline;">$34.00</s>
          </div>
        </div>
      </div>
      <div class="bb-sticky-atc__actions">
        <button type="button" class="bb-sticky-atc__button" id="bb-sticky-atc-submit"
          onclick="document.querySelector('.product-form__buttons button[type=submit], .product-form form button[type=submit]')?.click();">
          Add to cart
        </button>
      </div>
    </div>
  </div>

  <div id="harness-results" style="display:none;"></div>

  <!-- Include Core Theme Scripts -->
  <script>
    window.variantStrings = {
      addToCart: 'Add to cart',
      soldOut: 'Sold out',
      unavailable: 'Unavailable'
    };

    __CONSTANTS_JS__
    __PUBSUB_JS__
  </script>

  <!-- Sticky ATC Inlined Script -->
  <script>
    __STICKY_JS__
  </script>

  <!-- Adversarial Test Harness Runner -->
  <script>
    window.testLog = [];
    function record(testId, passed, message) {
      window.testLog.push({ id: testId, passed: passed, message: message });
    }

    // Fire DOMContentLoaded so sticky ATC initializes
    document.dispatchEvent(new Event('DOMContentLoaded'));

    (async function runStressTests() {
      try {
        const stickyPrice = document.getElementById('bb-sticky-price');
        const stickyCompare = document.getElementById('bb-sticky-compare-price');
        const stickyBtn = document.getElementById('bb-sticky-atc-submit');
        const stickyThumb = document.querySelector('.bb-sticky-atc__thumbnail');
        const nativeBtn = document.getElementById('ProductSubmitButton-template--main');

        // ADV-01: Baseline state
        record('ADV-01', 
          stickyPrice.textContent.trim() === '$24.00' &&
          stickyCompare.style.display !== 'none' &&
          stickyBtn.disabled === false &&
          stickyThumb.getAttribute('src') === 'https://example.com/initial-thumb.jpg',
          'Baseline state initialized cleanly'
        );

        // Helper: build HTML mock DOM for event
        function createProductDoc(isSale, regularPrice, salePrice) {
          const doc = document.implementation.createHTMLDocument('product');
          doc.body.innerHTML = 
            '<div class="product__info-container">' +
              '<div class="price ' + (isSale ? 'price--on-sale' : '') + '">' +
                '<div class="price__regular">' +
                  '<span class="price-item price-item--regular">' + regularPrice + '</span>' +
                '</div>' +
                '<div class="price__sale">' +
                  '<s class="price-item price-item--regular">' + regularPrice + '</s>' +
                  '<span class="price-item price-item--sale price-item--last">' + salePrice + '</span>' +
                '</div>' +
              '</div>' +
            '</div>';
          return doc;
        }

        // ADV-02: In-stock sale variant switch
        const saleDoc = createProductDoc(true, '$38.00', '$28.00');
        await publish(PUB_SUB_EVENTS.variantChange, {
          data: {
            variant: {
              id: 101,
              available: true,
              price: 2800,
              compare_at_price: 3800,
              featured_image: { src: 'https://cdn.example.com/variant-sale.jpg' }
            },
            html: saleDoc
          }
        });

        record('ADV-02',
          stickyPrice.textContent.trim() === '$28.00' &&
          stickyCompare.textContent.trim() === '$38.00' &&
          stickyCompare.style.display === 'inline' &&
          stickyThumb.getAttribute('src') === 'https://cdn.example.com/variant-sale.jpg' &&
          stickyBtn.disabled === false &&
          stickyBtn.textContent.trim() === 'Add to cart',
          'Sale variant synchronized price, compare-at, thumbnail, and button state'
        );

        // ADV-03: In-stock regular (non-sale) variant switch
        const regDoc = createProductDoc(false, '$45.00', '');
        await publish(PUB_SUB_EVENTS.variantChange, {
          data: {
            variant: {
              id: 102,
              available: true,
              price: 4500,
              compare_at_price: null,
              featured_image: { src: 'https://cdn.example.com/variant-reg.jpg' }
            },
            html: regDoc
          }
        });

        record('ADV-03',
          stickyPrice.textContent.trim() === '$45.00' &&
          stickyCompare.style.display === 'none' &&
          stickyThumb.getAttribute('src') === 'https://cdn.example.com/variant-reg.jpg' &&
          stickyBtn.disabled === false &&
          stickyBtn.textContent.trim() === 'Add to cart',
          'Regular variant synchronized regular price, hid compare-at, updated image and button'
        );

        // ADV-04: Sold out variant switch
        await publish(PUB_SUB_EVENTS.variantChange, {
          data: {
            variant: {
              id: 103,
              available: false,
              price: 4500,
              compare_at_price: null,
              featured_image: null
            },
            html: regDoc
          }
        });

        record('ADV-04',
          stickyBtn.disabled === true &&
          stickyBtn.textContent.trim() === 'Sold out' &&
          stickyThumb.getAttribute('src') === 'https://cdn.example.com/variant-reg.jpg',
          'Sold out variant correctly disabled button, updated label, and preserved thumbnail'
        );

        // ADV-05: Unavailable variant combination (variant: null)
        await publish(PUB_SUB_EVENTS.variantChange, {
          data: {
            variant: null,
            html: regDoc
          }
        });

        record('ADV-05',
          stickyBtn.disabled === true &&
          stickyBtn.textContent.trim() === 'Unavailable',
          'Unavailable variant (null) disabled button and set label to Unavailable'
        );

        // ADV-06: Missing window.variantStrings fallback resilience
        const originalVariantStrings = window.variantStrings;
        window.variantStrings = undefined;

        await publish(PUB_SUB_EVENTS.variantChange, {
          data: {
            variant: { id: 104, available: false }
          }
        });
        const soldOutFallbackPass = stickyBtn.disabled === true && stickyBtn.textContent.trim() === 'Sold out';

        await publish(PUB_SUB_EVENTS.variantChange, {
          data: { variant: null }
        });
        const unavailFallbackPass = stickyBtn.disabled === true && stickyBtn.textContent.trim() === 'Unavailable';

        await publish(PUB_SUB_EVENTS.variantChange, {
          data: { variant: { id: 105, available: true } }
        });
        const availableFallbackPass = stickyBtn.disabled === false && stickyBtn.textContent.trim() === 'Add to cart';

        window.variantStrings = originalVariantStrings;

        record('ADV-06',
          soldOutFallbackPass && unavailFallbackPass && availableFallbackPass,
          'Fallback text operates cleanly when window.variantStrings is undefined'
        );

        // ADV-07: Malformed event payload battery (Adversarial stress)
        let malformedThrew = false;
        try {
          await publish(PUB_SUB_EVENTS.variantChange, undefined);
          await publish(PUB_SUB_EVENTS.variantChange, {});
          await publish(PUB_SUB_EVENTS.variantChange, { data: {} });
          await publish(PUB_SUB_EVENTS.variantChange, { data: { variant: {} } });
          await publish(PUB_SUB_EVENTS.variantChange, { data: { variant: { featured_image: {} } } });
          await publish(PUB_SUB_EVENTS.variantChange, { data: { variant: { featured_image: { src: '' } } } });
          await publish(PUB_SUB_EVENTS.variantChange, { data: { html: document.createElement('div') } });
        } catch (e) {
          malformedThrew = true;
        }

        record('ADV-07',
          !malformedThrew,
          'Zero exceptions thrown during battery of malformed pub/sub event payloads'
        );

        // ADV-08: Native Form Submission Linkage
        let nativeClicked = false;
        nativeBtn.addEventListener('click', (e) => {
          nativeClicked = true;
          e.preventDefault();
        });

        stickyBtn.disabled = false;
        stickyBtn.click();

        record('ADV-08',
          nativeClicked === true,
          'Clicking sticky ATC button successfully dispatches click on native form submit button'
        );

        // ADV-09: Missing Thumbnail Element Resilience
        // Temporarily remove thumbnail element from DOM
        stickyThumb.remove();
        let thumbError = false;
        try {
          await publish(PUB_SUB_EVENTS.variantChange, {
            data: {
              variant: {
                id: 106,
                available: true,
                featured_image: { src: 'https://example.com/no-thumb.jpg' }
              }
            }
          });
        } catch (e) {
          thumbError = true;
        }

        record('ADV-09',
          !thumbError,
          'Sticky ATC safely handles products without thumbnail element without null reference errors'
        );

        // ADV-10: Rapid Sequential Variant Firing (Thrash / Race condition test)
        let thrashError = false;
        try {
          for (let i = 0; i < 50; i++) {
            const isAvail = (i % 2 === 0);
            publish(PUB_SUB_EVENTS.variantChange, {
              data: {
                variant: {
                  id: 200 + i,
                  available: isAvail,
                  price: 1000 + (i * 50)
                }
              }
            });
          }
        } catch (e) {
          thrashError = true;
        }

        // Final state: 49 is odd -> available: false -> Sold out
        record('ADV-10',
          !thrashError && stickyBtn.disabled === true && stickyBtn.textContent.trim() === 'Sold out',
          'Handled 50 rapid variant change events cleanly; final state is consistent'
        );

      } catch (err) {
        record('ADV-ERR', false, 'Unexpected harness exception: ' + err.toString());
      } finally {
        document.getElementById('harness-results').textContent = JSON.stringify(window.testLog);
      }
    })();
  </script>
</body>
</html>
'@

    $harnessHtml = $harnessHtmlTemplate `
        -replace '__CONSTANTS_JS__', $constantsJs `
        -replace '__PUBSUB_JS__', $pubsubJs `
        -replace '__STICKY_JS__', $stickyJs

    $tmpHarness = Join-Path $env:TEMP "adv_sticky_harness.html"
    $tmpOutput  = Join-Path $env:TEMP "adv_sticky_output.txt"
    Set-Content -Path $tmpHarness -Value $harnessHtml -Encoding UTF8

    # Execute harness in headless Edge and redirect output
    $cmd = "`"$edgePath`" --headless=new --disable-gpu --dump-dom `"file:///$($tmpHarness.Replace('\', '/'))`" > `"$tmpOutput`" 2>nul"
    cmd /c $cmd

    $dumpedDom = if (Test-Path $tmpOutput) { Get-Content $tmpOutput -Raw } else { "" }
    Remove-Item -Force $tmpHarness, $tmpOutput -ErrorAction SilentlyContinue

    if ($dumpedDom -match '<div id="harness-results"[^>]*>(.*?)</div>') {
        $jsonStr = $matches[1]
        try {
            $parsedResults = ConvertFrom-Json $jsonStr
            foreach ($res in $parsedResults) {
                Report-Result $res.id $res.message $res.passed $res.message
            }
        } catch {
            Report-Result "ADV-CHROMIUM-PARSE" "Parse Chromium test harness output" $false "Failed to parse JSON: $jsonStr"
        }
    } else {
        Report-Result "ADV-CHROMIUM-EXEC" "Execute Chromium test harness" $false "Could not extract test results from dumped DOM"
    }
}

# ------------------------------------------------------------------------------
# MODULE 2: Single-Variant & Multi-Variant Architecture & Edge Cases
# ------------------------------------------------------------------------------
Write-Host "`n=== MODULE 2: Variant Selection Edge Cases & Liquid Architecture ===" -ForegroundColor Magenta

# ADV-11: Single-Variant Product Architecture Guard
$pickerSnippet = Get-Content (Join-Path $projectRoot "snippets/product-variant-picker.liquid") -Raw
$hasOnlyDefaultGuard = $pickerSnippet -match '\{%-\s*unless\s+product\.has_only_default_variant\s*-%\}'
Report-Result "ADV-11" "product-variant-picker guards against single-variant redundant rendering" $hasOnlyDefaultGuard `
    "Single variant products must NOT render variant selects/radios; guarded by 'unless product.has_only_default_variant'"

# ADV-12: Multi-Variant Option Iteration & Web Component Bindings
$iteratesOptions = ($pickerSnippet -match 'for\s+option\s+in\s+product\.options_with_values') -and
                   ($pickerSnippet -match '<variant-selects') -and
                   ($pickerSnippet -match 'data-selected-variant')
Report-Result "ADV-12" "product-variant-picker iterates options and binds native variant-selects component" $iteratesOptions `
    "Multi-variant products must iterate options_with_values, bind <variant-selects>, and output data-selected-variant"

# ADV-13: Sold-Out Product-Level Guard in Sticky ATC
$stickyLiquid = Get-Content (Join-Path $projectRoot "snippets/sticky-add-to-cart.liquid") -Raw
$hasProductLevelGuard = $stickyLiquid -match '\{%-\s*if\s+product\s*!=\s*blank\s+and\s+product\.available\s*-%\}'
Report-Result "ADV-13" "sticky-add-to-cart guards entire rendering with product.available" $hasProductLevelGuard `
    "Entirely sold-out products must NOT render dead sticky ATC; guarded by 'if product != blank and product.available'"

# ------------------------------------------------------------------------------
# MODULE 3: Cart DOM Integrity & State Simulation Stress
# ------------------------------------------------------------------------------
Write-Host "`n=== MODULE 3: Cart DOM Integrity & State Simulation Stress ===" -ForegroundColor Magenta

# ADV-14: AST / Div Tag Balance and Non-Nesting in main-cart-items.liquid
$cartItemsLiquid = Get-Content (Join-Path $projectRoot "sections/main-cart-items.liquid") -Raw
$warningsStart = $cartItemsLiquid.IndexOf('<div class="cart__warnings">')
$cartFormStart = $cartItemsLiquid.IndexOf('<form action="{{ routes.cart_url }}"')
if ($cartFormStart -lt 0) {
    $cartFormStart = $cartItemsLiquid.IndexOf('id="cart"')
}

$balancePass = $false
$nestingPass = $false

if ($warningsStart -ge 0 -and $cartFormStart -gt $warningsStart) {
    $segment = $cartItemsLiquid.Substring($warningsStart, $cartFormStart - $warningsStart)
    $openDivs = [regex]::Matches($segment, '<div[\s>]').Count
    $closeDivs = [regex]::Matches($segment, '</div>').Count
    $balancePass = ($openDivs -eq $closeDivs) -and ($openDivs -gt 0)
    
    # Verify closing </div> comes immediately before <form
    $nestingPass = ($segment -match '</div>\s*$')
}

Report-Result "ADV-14" "main-cart-items.liquid cart__warnings div is perfectly balanced and closed before cart form" `
    ($balancePass -and $nestingPass) `
    "Open divs: $openDivs, Close divs: $closeDivs. Sibling relation to <form id='cart'>: $nestingPass"

# ADV-15: Empty Cart State Simulation in CSS & Markup
$compCartCss = Get-Content (Join-Path $projectRoot "assets/component-cart.css") -Raw
$emptyWarningsBlock = $compCartCss -match '\.is-empty\s+\.cart__warnings\s*\{\s*display:\s*block;'
$emptyContentsNone  = $compCartCss -match '\.is-empty\s+\.cart__contents'
$hasContinueShopping = $cartItemsLiquid -match 'routes\.all_products_collection_url'
$hasEmptyText = $cartItemsLiquid -match 'sections\.cart\.empty'

$emptyStatePass = $emptyWarningsBlock -and $emptyContentsNone -and $hasContinueShopping -and $hasEmptyText
Report-Result "ADV-15" "Empty cart state DOM & CSS rules properly display warnings and hide cart contents" $emptyStatePass `
    "Empty state rules: warnings block=$emptyWarningsBlock, contents none=$emptyContentsNone, links=$hasContinueShopping"

# ADV-16: Populated Cart State Simulation in CSS & Markup
$warningsHiddenByDefault = $compCartCss -match '\.cart__warnings\s*\{\s*display:\s*none;'
$hasCartItemsTable = $cartItemsLiquid -match '<table class="cart-items">'
$hasLineItemIteration = $cartItemsLiquid -match 'for\s+item\s+in\s+cart\.items'
$hasQuantityInputs = $cartItemsLiquid -match 'name="updates\[\]"'

$populatedStatePass = $warningsHiddenByDefault -and $hasCartItemsTable -and $hasLineItemIteration -and $hasQuantityInputs
Report-Result "ADV-16" "Populated cart state renders visible line items, quantity controls, and table outside warnings" $populatedStatePass `
    "Populated state: warnings hidden=$warningsHiddenByDefault, table=$hasCartItemsTable, line items=$hasLineItemIteration, qty=$hasQuantityInputs"

# ADV-17: Cart Drawer Direct Checkout Submission
$cartDrawerLiquid = Get-Content (Join-Path $projectRoot "snippets/cart-drawer.liquid") -Raw
$hasDrawerCheckout = ($cartDrawerLiquid -match 'name="checkout"') -and
                     ($cartDrawerLiquid -match 'id="CartDrawer-Checkout"') -and
                     ($cartDrawerLiquid -match 'form="CartDrawer-Form"') -and
                     ($cartDrawerLiquid -match 'disabled') # disabled on cart == empty
Report-Result "ADV-17" "Cart drawer provides direct checkout button with native form linkage and empty guard" $hasDrawerCheckout `
    "Cart drawer button must submit CartDrawer-Form with name='checkout' and be disabled when cart == empty"

# ------------------------------------------------------------------------------
# MODULE 4: Zero Mock Data & Fake Shipping Exhaustive Audit
# ------------------------------------------------------------------------------
Write-Host "`n=== MODULE 4: Zero Mock Data & Fake Shipping Exhaustive Audit ===" -ForegroundColor Magenta

# ADV-18: Exhaustive scan across ALL .liquid files in the theme
$liquidFiles = Get-ChildItem -Path $projectRoot -Recurse -Filter "*.liquid" | Where-Object { $_.FullName -notmatch '\\.agents\\' }
$mockFindings = [System.Collections.ArrayList]::new()

$mockPatterns = @(
    'free_shipping_threshold',
    'shipping_threshold\s*=',
    'free_shipping_amount',
    'mockData',
    'fakeCart',
    'dummyData',
    'mock_shipping',
    'simulateCheckout'
)

foreach ($file in $liquidFiles) {
    $content = Get-Content $file.FullName -Raw
    foreach ($pattern in $mockPatterns) {
        if ($content -match $pattern) {
            [void]$mockFindings.Add("$($file.Name): matches pattern '$pattern'")
        }
    }
}

$zeroMockLiquid = ($mockFindings.Count -eq 0)
$mockLiquidDetail = if ($zeroMockLiquid) { "Scanned $($liquidFiles.Count) Liquid files: ZERO mock patterns found" } else { ($mockFindings -join "; ") }
Report-Result "ADV-18" "Exhaustive scan of all Liquid files for mock shipping or fake cart data" $zeroMockLiquid $mockLiquidDetail

# ADV-19: Exhaustive scan across ALL .js files in assets/
$jsFiles = Get-ChildItem -Path (Join-Path $projectRoot "assets") -Filter "*.js"
$jsMockFindings = [System.Collections.ArrayList]::new()

$jsPatterns = @(
    'fakeCart',
    'mockData',
    'simulateCheckout',
    'dummyLineItems'
)

foreach ($file in $jsFiles) {
    $content = Get-Content $file.FullName -Raw
    foreach ($pattern in $jsPatterns) {
        if ($content -match $pattern) {
            [void]$jsMockFindings.Add("$($file.Name): matches pattern '$pattern'")
        }
    }
}

$zeroMockJs = ($jsMockFindings.Count -eq 0)
$mockJsDetail = if ($zeroMockJs) { "Scanned $($jsFiles.Count) JavaScript assets: ZERO mock patterns found" } else { ($jsMockFindings -join "; ") }
Report-Result "ADV-19" "Exhaustive scan of all JavaScript assets for mock/simulation code" $zeroMockJs $mockJsDetail

# ------------------------------------------------------------------------------
# SUMMARY & EXIT CODE
# ------------------------------------------------------------------------------
Write-Host "`n================================================================================" -ForegroundColor Cyan
Write-Host " ADVERSARIAL STRESS SUITE SUMMARY" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "Total Adversarial Tests: $($script:results.Count)"
Write-Host "Passed:                  $script:passedCount" -ForegroundColor Green
Write-Host "Failed:                  $script:failedCount" -ForegroundColor $(if ($script:failedCount -eq 0) { "Green" } else { "Red" })

$passRate = if ($script:results.Count -gt 0) { [Math]::Round(($script:passedCount / $script:results.Count) * 100, 1) } else { 0 }
Write-Host "Pass Rate:               $passRate%" -ForegroundColor Cyan

if ($script:failedCount -eq 0) {
    Write-Host "`nFINAL VERDICT: APPROVE (Zero Flaws Detected)" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nFINAL VERDICT: REQUEST_CHANGES ($script:failedCount Flaws Detected)" -ForegroundColor Red
    exit 1
}

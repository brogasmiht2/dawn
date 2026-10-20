# BalconyBloomCo Dawn 16.0 — Automated Test Infrastructure (`TEST_INFRA.md`)

## 1. Overview & Architecture

The BalconyBloomCo test infrastructure provides an automated, regression-proof quality gate built natively in PowerShell (5.1+ / 7+ compatible) without third-party runtime dependencies. The suite verifies that all custom storefront features, brand design system tokens, WCAG AA accessibility requirements, and native Shopify Dawn 16.0 purchasing workflows operate in strict accordance with `PROJECT.md` and `ORIGINAL_REQUEST.md`.

```
dawn/
├── tests/
│   ├── run_tests.ps1                           # Unified test suite CLI & reporting runner
│   ├── framework.ps1                           # Assertions, WCAG contrast calculations & AST helpers
│   ├── tier1_features/
│   │   ├── test_r1_config_schema.ps1           # R1: Theme Customizer & Schema Stability (11 tests)
│   │   ├── test_r2_design_system.ps1           # R2: Design System, Tokens, Contrast & Radii (12 tests)
│   │   ├── test_r3_accessibility_perf.ps1      # R3: WCAG Focus, ARIA Hygiene & Performance (9 tests)
│   │   └── test_r4_native_purchasing.ps1       # R4: Native DOM, PubSub & Variant Sync (9 tests)
│   ├── tier2_boundaries/
│   │   └── test_boundary_corner_cases.ps1      # Tier 2: Edge cases, extreme viewports & boundaries (8 tests)
│   ├── tier3_pairwise/
│   │   └── test_pairwise_combinations.ps1      # Tier 3: Cross-feature pairwise interactions (6 tests)
│   └── tier4_workloads/
│       └── test_workload_journeys.ps1          # Tier 4: Real-world customer end-to-end journeys (5 tests)
├── TEST_INFRA.md                               # Architecture and execution documentation
└── TEST_READY.md                               # Coverage matrix & baseline quality gate report
```

---

## 2. Test Suite Tiers & Coverage

The test suite contains **60 deterministic tests** distributed across 4 tiers:

### Tier 1: Feature Coverage (41 tests)
- **R1: Theme Customizer & Configuration Stability (11 tests)**
  - Valid JSON syntax in `config/settings_data.json` and `config/settings_schema.json`.
  - 5 complete color schemes (`scheme-1` through `scheme-5`) across `current` and `presets.Dawn`.
  - All 7 mandatory color properties (`background`, `background_gradient`, `text`, `button`, `button_label`, `secondary_button_label`, `shadow`) populated per scheme.
  - Page width slider step alignment `(page_width - min) % step == 0`.
  - 100% valid JSON syntax across all 13 template files in `templates/*.json` and section group files.
  - Custom section schemas valid with default presets and `color_scheme` exposures.
  - Typography scales configured for Garamond (`garamond_n4`) and Assistant (`assistant_n4`).
- **R2: Storefront Design System Cohesion (12 tests)**
  - Unified 4px border radii in `settings_data.json` (buttons, inputs, cards, collections, blogs, containers, media, popups, badges).
  - Unified 4px border radii tokens in `assets/balcony-bloom.css` (`--bb-radius-card`, `--bb-radius-btn`, `--bb-radius-badge` / pill).
  - Brand color tokens defined in CSS (`#244B3A` Forest Green, `#91A88F` Sage Green, `#F8F6EF` Warm Ivory, `#CE7958` Terracotta, `#EEF3ED` Soft Sage).
  - Active visual presence and utilization of Sage Green (`#91A88F`) across storefront surfaces.
  - WCAG AA contrast for text elements on Warm Ivory (`#F8F6EF`): Charcoal primary copy (13.7:1), accessible deepened terracotta eyebrows (`#B35634`, >= 4.5:1).
  - Sale badge color scheme contrast satisfying WCAG AA (>= 4.5:1).
  - `text-wrap: balance` coverage expanded to `h1-h6`, `.product__title`, `.collection-hero__title`, and search title.
  - Dedicated `.shopify-policy__container` CSS rules with constrained max-width and editorial line-height.
  - `templates/search.json` explicit `color_scheme` binding to active scheme.
- **R3: Accessibility & Responsive Verification (9 tests)**
  - Visible `:focus-visible` dual-layer halo / high-contrast outline ensuring >= 3:1 contrast on both light and dark buttons.
  - Focus ring contrast protection on dark hero banner overlays and sticky ATC buttons.
  - Category grid responsive 2-up layout via `@media screen and (max-width: 749px)` on `.bb-category-grid`.
  - Minimum 44px tap target height on mobile sticky ATC button (`.bb-sticky-atc__button`).
  - Decorative SVG hygiene: `aria-hidden="true"` on trust badge SVGs in `snippets/cart-drawer.liquid`, `sections/main-cart-footer.liquid`, and `sections/gardening-guides.liquid`.
  - Hero banner fallback image specifies `fetchpriority="high"` and explicit dimensions (`width="1920"`, `height="1080"`).
- **R4: Native Shopify Architecture Preservation (9 tests)**
  - DOM integrity: `<div class="cart__warnings">` in `sections/main-cart-items.liquid` closed before `<form id="cart">`.
  - Cart line items table located outside `.cart__warnings` so it remains visible when cart is not empty.
  - Elimination of hardcoded mock shipping data (`free_shipping_threshold = 5000`).
  - Sticky Add to Cart variant synchronization: subscribes to `PUB_SUB_EVENTS.variantChange`.
  - Sticky Add to Cart updates `#bb-sticky-price` and `#bb-sticky-compare-price` on variant change.
  - Sticky Add to Cart synchronizes thumbnail image to variant's `featured_image.src`.
  - Sticky Add to Cart disables submit button and updates text for sold out / unavailable variants.
  - Cart drawer native checkout link preservation (`name="checkout"` / direct checkout route).
  - Preservation of native Dawn JavaScript components without mock intercepts.

### Tier 2: Boundary & Corner Cases (8 tests)
- Empty cart vs populated cart conditional routing (`routes.all_products_collection_url`, `sections.cart.empty`).
- Multi-variant product support: `main-product.liquid` renders `product-variant-picker` and iterates `product.options_with_values`.
- Null and sold out variant safety in sticky ATC script.
- 390px mobile viewport: absence of unbounded min-width declarations causing horizontal overflow.
- 768px tablet viewport: clean breakpoint transitions at 749px/750px.
- 1440px desktop viewport: max-width container constraints.
- Solid background hex validity when `background_gradient` is empty string.
- Step boundary math validation across all range sliders in `config/settings_schema.json`.

### Tier 3: Cross-Feature Combinations (6 tests)
- Event chain: Variant Picker (`product-info.js`) -> Sticky ATC (`PUB_SUB_EVENTS.variantChange`) -> Native Form Submit -> Cart Drawer (`PUB_SUB_EVENTS.cartUpdate`).
- Style cohesion: Search Template scheme + 4px Card Radii + 4px Facet Pills.
- Dark surface contrast: Hero banner overlay + accessible focus rings.
- Cart drawer: Scheme-1 + Soft Sage trust badges + ARIA SVGs.
- Touch & responsive interaction: Mobile 2-up category grid + 44px button tap targets.
- Homepage alternating section color scheme rhythm without consecutive clashes.

### Tier 4: Real-World Workload Scenarios (5 tests)
- **JOURNEY-01**: New Visitor Discovery & Collection Browsing Journey (Hero banner -> mobile 2-up category browsing -> collection grid with 4px cards and balanced typography).
- **JOURNEY-02**: PDP Variant Customization & Sticky Purchase Journey (Product page load -> variant option selection -> real-time price & image sync -> sticky bar visibility -> cart submission).
- **JOURNEY-03**: Cart Management & Direct Checkout Journey (Cart drawer open -> soft sage trust badges -> navigation to `/cart` -> visible cart table -> absence of fake threshold -> direct checkout).
- **JOURNEY-04**: Accessibility & Keyboard-Only Navigation Journey (Tab navigation -> dual-layer focus rings -> screen reader skip on decorative SVGs -> policy page reading container).
- **JOURNEY-05**: Theme Merchant Customization & Schema Stability Journey (Theme Editor JSON schema validation -> valid page_width range step -> 5 complete color schemes -> custom section presets).

---

## 3. Mathematical & Algorithmic Test Derivations

### WCAG 2.1 Color Contrast Calculation
The test framework implements the official W3C relative luminance formula:
$$L = 0.2126 \times R_{\text{linear}} + 0.7152 \times G_{\text{linear}} + 0.0722 \times B_{\text{linear}}$$
Where each channel $C \in \{R, G, B\}$ normalized to $[0, 1]$ is linearized:
$$C_{\text{linear}} = \begin{cases} \frac{C}{12.92} & \text{if } C \le 0.04045 \\ \left(\frac{C + 0.055}{1.055}\right)^{2.4} & \text{otherwise} \end{cases}$$
The contrast ratio between two colors is:
$$\text{Contrast Ratio} = \frac{L_1 + 0.05}{L_2 + 0.05} \quad (L_1 \ge L_2)$$
- Normal text requires $\ge 4.5:1$ (WCAG AA).
- Large text / graphical UI components require $\ge 3.0:1$ (WCAG AA).

### DOM Nesting Balance Verification
In `test_r4_native_purchasing.ps1`, the test slices the Liquid DOM from `<div class="cart__warnings">` up to `<form id="cart">` and executes an AST tag balance check:
$$\Delta = \text{Count}(\text{open } \texttt{<div>}) - \text{Count}(\text{close } \texttt{</div>}) = 0$$
If $\Delta \ne 0$, the cart form is trapped inside the hidden warnings container.

---

## 4. Execution Commands

### Run Full Test Suite
```powershell
powershell -ExecutionPolicy Bypass -File tests/run_tests.ps1
```

### Run Specific Test Tier
```powershell
# Tier 1: Feature Coverage
powershell -ExecutionPolicy Bypass -File tests/run_tests.ps1 -Tier 1

# Tier 2: Boundary & Corner Cases
powershell -ExecutionPolicy Bypass -File tests/run_tests.ps1 -Tier 2

# Tier 3: Pairwise Interactions
powershell -ExecutionPolicy Bypass -File tests/run_tests.ps1 -Tier 3

# Tier 4: Real-World Workloads
powershell -ExecutionPolicy Bypass -File tests/run_tests.ps1 -Tier 4
```

### Run Filtered Tests by Pattern
```powershell
# Filter by test ID or keyword
powershell -ExecutionPolicy Bypass -File tests/run_tests.ps1 -Filter "R1"
powershell -ExecutionPolicy Bypass -File tests/run_tests.ps1 -Filter "contrast"
powershell -ExecutionPolicy Bypass -File tests/run_tests.ps1 -Filter "sticky"
```

### Exit Codes
- `0`: All executed tests PASSED (100% Green).
- `1`: One or more tests FAILED (Detailed breakdown printed).
- `2`: Framework or configuration error.

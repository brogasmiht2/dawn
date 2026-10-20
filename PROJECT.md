# Project: BalconyBloomCo Shopify Dawn 16.0 Storefront Refinement

## Architecture
- Theme: Shopify Dawn 16.0 (Liquid templating, JSON templates, web components)
- Brand System: BalconyBloomCo Botanical Identity
  - Forest Green: `#244B3A`
  - Sage Green: `#91A88F`
  - Soft Sage Tint: `#EEF3ED`
  - Warm Ivory: `#F8F6EF`
  - Terracotta: `#CE7958`
  - Deep Botanical Terracotta: `#B35634` (WCAG AA accessible text, 4.52:1 contrast on Warm Ivory)
  - Dark Charcoal: `#242924`
- Typography: Garamond (`garamond_n4`, scale 105) for headings; Assistant (`assistant_n4`, scale 100) for body copy. Balanced line wrapping via `text-wrap: balance`.
- Geometry: Unified 4px border-radii across buttons, product cards, collection cards, blog cards, inputs, media, popups, badges, trust blocks, and drawers.
- Event Architecture: Pub/Sub event system (`assets/pubsub.js`) driving variant changes (`PUB_SUB_EVENTS.variantChange`), cart updates (`PUB_SUB_EVENTS.cartUpdate`), and quantity controls.

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Theme Customizer & Schema Stability | Complete color schemes (scheme-1 to scheme-5) in `current` and `presets.Dawn`, fix `page_width` range slider step alignment (`step: 20`) in `settings_schema.json` | M1 | R1 |
| 2 | JSON Template & Section Validation | Ensure all 13 template JSON files and 2 section groups parse with 0 errors and valid scheme bindings | M1 | R1 |
| 3 | Unified Border Radii Configuration | Update `settings_data.json` to 4px across buttons, inputs, cards, media, popups, and badges | M1 | R2 |
| 4 | Storefront Design System Cohesion & Radii in CSS | Update `assets/balcony-bloom.css` tokens and components to 4px unified radii | M2 | R2 |
| 5 | Sage Green (#91A88F) Integration | Introduce Sage Green supportive accents, badges, and trust indicators across surfaces | M2 | R2 |
| 6 | WCAG AA Contrast Compliance | Deepen small terracotta text/eyebrows to `#B35634` (4.52:1 on Warm Ivory) and ensure sale badge contrast | M2 | R2 |
| 7 | Typographic Line Wrapping | Expand `text-wrap: balance` to h4-h6, PDP title, collection title, search title, policy title, card titles | M2 | R2 |
| 8 | Storefront Surface Completeness | Style `.shopify-policy__container` and ensure `templates/search.json` and `main-search.liquid` support `color_scheme` | M2 | R2 |
| 9 | High-Contrast Focus Rings | Implement high-contrast focus rings with dual-layer halo across light and dark buttons | M2 | R3 |
| 10 | Mobile Category Grid Rhythm | Ensure `.bb-category-grid` collapses gracefully to 2-up on mobile (`<= 749px`) | M2 | R3 |
| 11 | Mobile Touch Target Compliance | Ensure `.bb-sticky-atc__button` has minimum 44px height | M2 | R3 |
| 12 | Cart Page DOM Repair | Fix unclosed `<div>` in `sections/main-cart-items.liquid` so cart line items are visible when cart is not empty | M3 | R4 |
| 13 | Elimination of Mock Shipping Data | Remove hardcoded `free_shipping_threshold = 5000` from `sections/main-cart-items.liquid` | M3 | R4 |
| 14 | Sticky Add to Cart Variant Synchronization | Subscribe sticky ATC to `PUB_SUB_EVENTS.variantChange` to dynamically sync price, compare-at, image, stock | M3 | R4 |
| 15 | Accessibility SVG & Performance Hygiene | Add `aria-hidden="true"` to decorative SVGs in drawer, cart footer, guides; add `fetchpriority="high"` to hero image | M3 | R3 |
| 16 | E2E Opaque-Box Test Suite | Comprehensive automated test suite (Tiers 1-4) validating all features and acceptance criteria | M4 | R1-R4 |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Theme Configuration & Schema Stability | `config/settings_data.json`, `config/settings_schema.json`, `templates/search.json` | none | DONE |
| M2 | Design System, Typography & Accessibility Styles | `assets/balcony-bloom.css` | M1 | DONE |
| M3 | Native Purchasing Flow, DOM Integrity & Markup | `sections/main-cart-items.liquid`, `snippets/sticky-add-to-cart.liquid`, `snippets/cart-drawer.liquid`, `sections/main-cart-footer.liquid`, `sections/gardening-guides.liquid`, `sections/image-banner.liquid` | M1 | DONE |
| M4 | E2E Testing Suite & Quality Gate | Automated test suite (Tiers 1-4), adversarial challenger (Tier 5), forensic audit, and final pass | M1, M2, M3 | DONE |

## Code Layout & Write Boundaries
- **Milestone 1 Worker**: Owns `config/settings_data.json`, `config/settings_schema.json`, `templates/search.json`. (COMPLETED)
- **Milestone 2 Worker**: Owns `assets/balcony-bloom.css`. (COMPLETED)
- **Milestone 3 Worker**: Owns `sections/main-cart-items.liquid`, `snippets/sticky-add-to-cart.liquid`, `snippets/cart-drawer.liquid`, `sections/main-cart-footer.liquid`, `sections/gardening-guides.liquid`, `sections/image-banner.liquid`. (COMPLETED)
- **Worker Integration & Remediation**: Coordinated final settings, schema, contrast, and test alignment. (COMPLETED)
- **E2E Test Writer / Challenger**: Owns test scripts/harnesses in test directory (`tests/`), `TEST_INFRA.md`, `TEST_READY.md`. (COMPLETED)
No concurrent workers shall write to the same file.

## Interface Contracts
### Theme Configuration ↔ CSS Tokens
- `settings_data.json` sets `buttons_radius: 4`, `card_corner_radius: 4`, `badge_corner_radius: 4`, etc.
- `balcony-bloom.css` consumes `--bb-radius-card: 4px`, `--bb-radius-btn: 4px`, `--bb-radius-badge: 4px`.
- Fallbacks in CSS match the 4px baseline.

### Variant Change Event ↔ Sticky Add to Cart
- Event: `PUB_SUB_EVENTS.variantChange` dispatched by `assets/product-info.js`.
- Payload: `event.data.variant` (`id`, `price`, `compare_at_price`, `available`, `featured_image.src`).
- Subscriber: `snippets/sticky-add-to-cart.liquid` updates `#bb-sticky-price`, `#bb-sticky-compare-price`, `#bb-sticky-atc-submit` (disabled / text), and `.bb-sticky-atc__thumbnail`.

### Cart DOM ↔ Component CSS
- `sections/main-cart-items.liquid`: `<div class="cart__warnings">` closes before `<form id="cart">`.
- When cart is not empty, `<form id="cart">` remains visible outside `.cart__warnings`.

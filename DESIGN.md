---
name: BalconyBloomCo
description: Premium botanical e-commerce design system for small-space urban gardening.
colors:
  forest-green: "#244B3A"
  sage-green: "#91A88F"
  warm-ivory: "#F8F6EF"
  terracotta: "#CE7958"
  charcoal: "#242924"
  white: "#FFFFFF"
  soft-sage: "#EEF3ED"
  border-subtle: "rgba(36, 75, 58, 0.12)"
  border-medium: "rgba(36, 75, 58, 0.22)"
  shadow-light: "rgba(0, 0, 0, 0.06)"
  shadow-card: "rgba(0, 0, 0, 0.08)"
  shadow-hero: "rgba(0, 0, 0, 0.25)"
typography:
  display:
    fontFamily: "Garamond, Playfair Display, serif"
    fontSize: "clamp(2.5rem, 5vw, 4.4rem)"
    fontWeight: 500
    lineHeight: 1.15
    letterSpacing: "-0.02em"
  display-hero:
    fontSize: "3rem"
  display-header:
    fontSize: "2.6rem"
  heading:
    fontFamily: "Garamond, Playfair Display, serif"
    fontSize: "clamp(1.8rem, 3vw, 2.8rem)"
    fontWeight: 500
    lineHeight: 1.25
    letterSpacing: "-0.015em"
  heading-xl:
    fontSize: "2.2rem"
  heading-lg:
    fontSize: "2rem"
  heading-md:
    fontSize: "1.85rem"
  heading-sm:
    fontSize: "1.7rem"
  body:
    fontFamily: "Assistant, -apple-system, sans-serif"
    fontSize: "1.6rem"
    fontWeight: 400
    lineHeight: 1.55
    letterSpacing: "0.01em"
  body-sm:
    fontSize: "1.5rem"
  body-xs:
    fontSize: "1.4rem"
  caption-lg:
    fontSize: "1.35rem"
  caption:
    fontSize: "1.3rem"
  badge:
    fontSize: "1.25rem"
  subheading:
    fontFamily: "Assistant, -apple-system, sans-serif"
    fontSize: "1.2rem"
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: "0.12em"
  tag-sm:
    fontSize: "1.15rem"
  tag-xs:
    fontSize: "1.1rem"
rounded:
  xs: "2px"
  sm: "4px"
  btn: "6px"
  md: "8px"
  card: "10px"
  lg: "12px"
  pill: "30px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "16px"
  lg: "24px"
  xl: "32px"
  xxl: "48px"
components:
  button-primary:
    backgroundColor: "{colors.forest-green}"
    textColor: "{colors.white}"
    rounded: "{rounded.md}"
    padding: "12px 28px"
  button-primary-hover:
    backgroundColor: "{colors.terracotta}"
  button-secondary:
    backgroundColor: "transparent"
    textColor: "{colors.forest-green}"
    rounded: "{rounded.md}"
    padding: "12px 28px"
---

## Overview

BalconyBloomCo is a premium botanical direct-to-consumer brand for urban and apartment gardeners. The design embodies modern naturalism: calm, trustworthy, practical, and editorial, avoiding cluttered or generic dropshipping templates.

## Colors

- **Forest Green (`#244B3A`):** The primary brand anchor, used for primary calls to action, prominent logos, header highlights, and deep accents.
- **Sage Green (`#91A88F`):** Calming botanical secondary accent for soft tags, supportive icons, and muted highlights.
- **Warm Ivory (`#F8F6EF`):** Editorial background tone offering warmth and contrast against stark white.
- **Terracotta (`#CE7958`):** Restrained, deliberate accent color for sale pricing, urgency highlights, and secondary interactive moments.
- **Dark Charcoal (`#242924`):** High-contrast, readable body copy color.
- **Soft Sage (`#EEF3ED`):** Background wash for alternating benefit sections.

## Typography

- **Headings & Display:** Classic serif (Garamond / Playfair) set with tight letter-spacing and balanced wrap (`text-wrap: balance`), delivering an editorial feel.
- **Body & Controls:** Humanist sans-serif (Assistant) engineered for legibility at small sizes, optimal line lengths under 75 characters, and tabular numbers for pricing (`font-variant-numeric: tabular-nums`).
- **Eyebrows & Subheadings:** Uppercase spaced tracking (0.12em) used purposefully for section classification.

## Layout

- Desktop page width max: 1240px with generous, balanced margins.
- Clean column rhythms: 4-up desktop grids for products, 5-up for categories, collapsing gracefully to 2-up on tablet and mobile.
- Zero horizontal overflow; intentional vertical spacing without oversized empty voids.

## Elevation & Depth

- Restrained elevation: Subtle borders (`rgba(36, 75, 58, 0.12)`) paired with soft, natural drop-shadows (`0 4px 20px rgba(36, 41, 36, 0.06)`).
- Frosted glass treatment (`backdrop-filter: blur(8px)`) on hero banner cards for legibility over rich photography.

## Shapes

- Cohesive border-radii: 8px on product cards, inputs, and standard containers; 30px on badges and pills.
- Avoiding overly bubbly or hyper-rounded gimmicks.

## Components

- **Product Cards:** Crisp image framing, subtle hover elevation, clear prices, and accessible quick-add trigger.
- **Hero Banner:** Full-viewport impact with high-contrast text overlay card, accessible CTA buttons, and prioritized above-the-fold image loading.
- **Navigation & Sticky ATC:** Smooth mobile sticky purchase bar with real-time stock feedback, and clean mobile drawer menu.
- **Interactive Controls:** Visible `:focus-visible` rings with offset, honoring `prefers-reduced-motion`.

## Do's and Don'ts

### Do
- Use real product data, true availability, and honest pricing.
- Keep typography balanced with generous whitespace and editorial hierarchy.
- Maintain WCAG AAA/AA color contrast across all text elements.
- Test responsive layouts at 390px, 768px, and 1440px viewports.

### Don't
- Don't invent fake promotional countdowns, free shipping thresholds, or deceptive badges.
- Don't use `transition: all` or jarring animations.
- Don't duplicate newsletter signup forms in both main page content and footer simultaneously.
- Don't use non-semantic click divs for navigation or action controls.

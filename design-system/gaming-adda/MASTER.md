# Design System Master File

> **LOGIC:** When building a specific page, first check `design-system/pages/[page-name].md`.
> If that file exists, its rules **override** this Master file.
> If not, strictly follow the rules below.

---

**Project:** Gaming Adda
**Generated:** 2026-07-18
**Category:** Casual board & arcade games

Aligned with the Flutter app theme (teal seed `#0D9488`, Fredoka + Nunito).

---

## Global Rules

### Color Palette

| Role | Hex | CSS Variable |
|------|-----|--------------|
| Primary | `#0D9488` | `--color-primary` |
| Secondary | `#14B8A6` | `--color-secondary` |
| CTA/Accent | `#F59E0B` | `--color-cta` |
| Background | `#F0FDFA` | `--color-background` |
| Surface | `#FFFFFF` | `--color-surface` |
| Text | `#134E4A` | `--color-text` |
| Muted | `#3F6864` | `--color-muted` |

**Color Notes:** Playful teal + amber action — matches app store / Material seed.

### Typography

- **Heading Font:** Fredoka
- **Body Font:** Nunito
- **Mood:** playful, friendly, fun, creative, approachable
- **Google Fonts:** [Fredoka + Nunito](https://fonts.google.com/share?selection.family=Fredoka:wght@400;500;600;700|Nunito:wght@300;400;500;600;700)

**CSS Import:**
```css
@import url('https://fonts.googleapis.com/css2?family=Fredoka:wght@400;500;600;700&family=Nunito:wght@300;400;500;600;700&display=swap');
```

### Spacing Variables

| Token | Value | Usage |
|-------|-------|-------|
| `--space-xs` | `4px` / `0.25rem` | Tight gaps |
| `--space-sm` | `8px` / `0.5rem` | Icon gaps, inline spacing |
| `--space-md` | `16px` / `1rem` | Standard padding |
| `--space-lg` | `24px` / `1.5rem` | Section padding |
| `--space-xl` | `32px` / `2rem` | Large gaps |
| `--space-2xl` | `48px` / `3rem` | Section margins |
| `--space-3xl` | `64px` / `4rem` | Hero padding |

### Shadow Depths (Clay)

| Level | Value | Usage |
|-------|-------|-------|
| `--shadow-clay` | `6px 6px 0 #0D948833, inset 0 -4px 0 #0D948822` | Soft 3D clay lift |
| `--shadow-clay-hover` | `8px 8px 0 #0D948844, inset 0 -4px 0 #0D948822` | Hover lift |
| `--shadow-press` | `2px 2px 0 #0D948833, inset 0 3px 0 #0D948822` | Soft press |

---

## Component Specs

### Buttons

```css
.btn-primary {
  background: #F59E0B;
  color: #134E4A;
  padding: 14px 28px;
  border: 3px solid #134E4A;
  border-radius: 20px;
  font-weight: 700;
  box-shadow: 4px 4px 0 #134E4A33;
  transition: all 200ms ease-out;
  cursor: pointer;
}

.btn-primary:hover {
  box-shadow: 6px 6px 0 #134E4A44;
  transform: translateY(-2px);
}

.btn-primary:active {
  box-shadow: 2px 2px 0 #134E4A33;
  transform: translateY(1px);
}
```

### Cards (interactive only)

```css
.card {
  background: #FFFFFF;
  border: 3px solid #134E4A22;
  border-radius: 24px;
  padding: 24px;
  box-shadow: var(--shadow-clay);
  transition: all 200ms ease-out;
  cursor: pointer;
}

.card:hover {
  box-shadow: var(--shadow-clay-hover);
  transform: translateY(-2px);
}
```

---

## Style Guidelines

**Style:** Claymorphism

**Keywords:** Soft 3D, chunky, playful, toy-like, bubbly, thick borders (3–4px), double shadows, rounded (16–24px)

**Key Effects:** Inner+outer shadows, soft press (200ms ease-out), fluffy elements, smooth transitions

### Page Pattern

**Pattern Name:** App Store Style Landing

- **CTA Placement:** Above fold + after games grid
- **Section Order:** Hero (brand + CTA) → Games grid → Features → Final CTA

---

## Anti-Patterns (Do NOT Use)

- ❌ Generic design / no personality
- ❌ Purple-on-white or dark neon themes (brand is teal)
- ❌ Emojis as icons — use SVG
- ❌ Missing `cursor: pointer` on clickables
- ❌ Layout-shifting scale hovers
- ❌ Low contrast text (< 4.5:1)
- ❌ Ignoring `prefers-reduced-motion`

---

## Pre-Delivery Checklist

- [ ] No emojis used as icons
- [ ] `cursor-pointer` on all clickable elements
- [ ] Hover states with smooth transitions (150–300ms)
- [ ] Light mode text contrast 4.5:1 minimum
- [ ] Focus states visible for keyboard navigation
- [ ] `prefers-reduced-motion` respected
- [ ] Responsive: 375px, 768px, 1024px, 1440px

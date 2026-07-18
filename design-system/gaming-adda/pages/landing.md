# Landing Page Override

**Page:** Marketing landing (`website/`)
**Overrides Master:** Hero structure, section order

## Sections

1. **Hero** — Brand “Gaming Adda” as dominant signal, one headline, one support line, Play CTA. Soft mint gradient atmosphere; no cards in hero.
2. **Games** — Interactive clay cards for every title; each links into the Flutter web app (`play/`).
3. **Features** — Three short benefits (instant play, offline-friendly board classics, levels & AI).
4. **Final CTA** — Repeat Play button.

## Motion

- Soft float on hero blob (disabled under `prefers-reduced-motion`)
- Clay press on buttons/cards (200ms ease-out)
- Stagger fade-in for game cards on scroll (optional, respect reduced motion)

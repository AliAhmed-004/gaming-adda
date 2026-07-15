# Checkers Settings Page Overrides

> **PROJECT:** Gaming Adda  
> **Page:** Checkers setup / settings menu  
> Overrides `MASTER.md` for this immersive game surface.

---

## Style

- **Primary styles:** Skeuomorphism + Claymorphism (tactile wood panel, glossy buttons)
- **Mood:** Casual mobile game menu (jungle frame + wooden board)
- **Fonts:** Fredoka (titles/buttons) + Nunito (helper copy) — playful gaming pairing
- **Avoid:** Flat enterprise blues, white text on cream, emoji icons

## Colors (wood / jungle)

| Role | Hex | Usage |
|------|-----|--------|
| Panel cream | `#E8D9B8` | Panel interior |
| Wood brown | `#5C2E0A` | Labels on cream (contrast) |
| Title yellow | `#FFE566` | Banner title |
| CTA green | pill green asset | Mode options |
| Primary CTA | pill gold asset | Start Game |
| Exit | pill red asset | Back |
| Accent blue | circle blue asset | Home |

## Layout

1. Full-bleed `assets/ui/bg_jungle.png`
2. Centered wood panel (max ~400px, responsive)
3. Top: 4 circle actions (Sound, Music, Help, Home) — min 48×48
4. Mode pills (Vs Computer, 2 Players) — equal weight, selected ring
5. Primary CTA: Start Game (gold)
6. Secondary exit: Back (red)
7. Gaps ≥ 12px between touch targets

## UX rules

- Touch targets ≥ 44×44; gaps ≥ 8px (prefer 12)
- Labels on cream: dark brown `#4A2C14` (not white)
- Press scale 0.95 (200ms); respect `prefers-reduced-motion`
- Visible focus rings for keyboard/TV
- Semantic labels + selected state for modes/toggles
- One clear Start CTA; Back preserves nav history (`pop`)

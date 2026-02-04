---
name: managed-hosting-comparison
description: Detailed comparison of Urbit managed hosting providers including Tlon, Red Horizon, and self-hosting options with 2025 pricing, features, SLAs, migration procedures, and decision frameworks. Use when evaluating hosting options, comparing providers, planning migrations, or making build-vs-buy decisions.
user-invocable: true
disable-model-invocation: false
---

# Managed Hosting Comparison Skill

Detailed comparison of Urbit managed hosting providers with pricing, features, SLAs, and decision matrices (2025).

## Provider Matrix

| Provider | Cost | SLA | Support | Custom Apps | Dojo Access | Best For |
|----------|------|-----|---------|-------------|-------------|----------|
| **Tlon** | Free tier + ~$20/mo paid | Best-effort | Email | No | No | New users, social |
| **Red Horizon** | FREE | 99.99% | Professional | Limited | Limited | Business, reliability |
| **Self-Hosting** | Hardware + $5/mo | User | Community | Yes | Yes | Technical, privacy |
| **VPS** | $12-24/mo | 99.9% | Provider | Yes | Yes | Developers, control |

## Detailed Comparisons

### Tlon Hosting
**Pros**: Official, mobile apps, free tier available, paid plans (~$20/mo) for additional features and reliability
**Cons**: No dojo, limited apps, no SLA on free tier, export delays
**Ideal**: Casual users, social networking, exploration
**Migration**: Email support@tlon.io for pier import/export
**Note**: Tlon now offers paid hosting plans (~$20/mo) in addition to the free tier.

### Red Horizon
**Pros**: Professional SLA, crypto-native, security-focused, backup included, FREE hosting
**Cons**: Less customization than VPS
**Ideal**: Businesses, uptime-critical apps, professional support needs
**Pricing**: FREE (users provide valuable insights for long-term vision of scalable Urbit hosting for millions)

### UrbitHost (Absorbed into Tlon Hosting)
**Note**: UrbitHost is no longer an independent provider. Its hosting capabilities were absorbed into Tlon Hosting. Users previously on UrbitHost should refer to the Tlon Hosting section above.
**Legacy Tech**: K8s stateful sets, permanent volumes, auto-failover

### Native Planet (Self-Hosting)
**Pros**: Full control, privacy, multi-ship (GroundSeg), one-time hardware cost
**Cons**: Technical setup, electricity costs, home network management
**Ideal**: Privacy-focused, tech enthusiasts, multi-ship fleets (5+)
**Cost**: $300-800 hardware + $5-10/mo StarTram

### VPS (Self-Managed)
**Pros**: Full control, custom apps, dojo access, affordable
**Cons**: Technical management, no built-in support
**Ideal**: Developers, learners, custom requirements
**Cost**: $6-24/mo (Hetzner to DigitalOcean)

## Decision Tree

**Start Here**: What's your priority?

1. **Cost = $0** → Tlon (free tier) or Red Horizon
2. **Uptime SLA critical** → Red Horizon or Tlon (paid plan)
3. **Full control needed** → VPS or Self-Hosting
4. **Non-technical user** → Tlon or Red Horizon
5. **Privacy paramount** → Self-Hosting
6. **Multi-ship fleet (5+)** → Self-Hosting (GroundSeg)
7. **Learning/development** → VPS

## Feature Comparison

**Backup/Recovery**:
- Tlon: Manual export request
- Red Horizon: Automated, included
- Self-Hosting: User-managed
- VPS: User-managed

**Networking**:
- Tlon: Automatic (tlon.network URLs)
- Red Horizon: Custom domains supported
- Self-Hosting: StarTram or Anchor
- VPS: arvo.network or custom (user-configured)

**Monitoring**:
- Tlon: Provider-managed (no user access)
- Red Horizon: Provider dashboards
- Self-Hosting: User-configured (Prometheus/Grafana)
- VPS: User-configured

## Pricing Summary (Annual)

- **Tlon**: $0/year (free tier) or ~$240/year (paid plan at ~$20/mo)
- **Red Horizon**: $0/year (FREE)
- **Self-Hosting**: $300-800 (Year 1 hardware) + $60-120/year (StarTram)
- **VPS (Hetzner)**: $78/year
- **VPS (DigitalOcean)**: $288/year

## Reference

- Tlon: https://tlon.io
- Red Horizon: https://redhorizon.com
- UrbitHost (historical): https://urbit.org/blog/urbithost-interview
- Native Planet: https://www.nativeplanet.io

## Summary

Managed hosting options span free (Tlon free tier, Red Horizon) to paid (~$20/mo Tlon paid plan) to self-managed ($6-24/mo VPS, $300+ hardware self-hosting). UrbitHost was absorbed into Tlon Hosting. Decision factors: budget (Tlon free tier/Red Horizon free, VPS $6+, Tlon paid ~$20/mo), technical expertise (managed low, VPS medium, self-hosting high), control needs (self-hosting > VPS > managed), and uptime requirements (managed hosting SLA 99.9-99.99% > VPS 99.9% > self-hosting variable). Best path: Tlon (explore) → VPS (learn) → choose managed (convenience) or self-hosting (privacy/scale).

---
name: fleet-operations
description: Large-scale Urbit ship fleet management for 5-100+ ships including resource planning, batch operations, automation, Infrastructure-as-Code with Terraform, Helm templating, and GitOps workflows. Use when managing ship fleets, planning large deployments, automating operations, or implementing IaC for Urbit infrastructure.
user-invocable: true
disable-model-invocation: false
validated: null
checked-by: ~sarlev-sarsen
notes: Fleet Operations skill included `sudo wget * | bash` command. It was from get.groundseg.app which is technically a trusted location, but large scale fleet operations should probably not be done haphazardly with a random skill off the internet. See the git history if you would like to see an rough overview of what it would take to run a fleet of urbit ships.
---

Fleet operations for 5+ Urbit ships requires resource planning (4GB RAM, 50-100GB disk per ship), orchestration tooling (GroundSeg for <25 ships, Kubernetes for 25+), and centralized monitoring (Prometheus/Grafana). Batch operations enable mass |pack, rolling updates, and staggered startups. Cost optimization: shared monitoring infrastructure, reserved instances (30-50% savings), and rightsizing based on utilization. Best practices: rolling operations (zero-downtime), automated backups, configuration management (Ansible/Terraform), and comprehensive documentation. Typical fleet costs: 5 ships ($40-80/mo), 10 ships ($80-160/mo), 25+ ships ($200+/mo) with Kubernetes management.

---
name: performance-engineer-assistant
description: Urbit ship performance optimization expert for tuning CPU, disk I/O, memory, and network. Use when optimizing ship performance, troubleshooting bottlenecks, planning capacity, or setting up monitoring and SLAs.
user-invocable: true
disable-model-invocation: false
validated: safe
checked-by: ~sarlev-sarsen
---

# Performance Engineer

Expert guidance for optimizing Urbit ship performance across system-level tuning, application profiling, capacity planning, and SLA compliance.

## Performance Domains

### 1. System-Level
- **I/O Scheduler**: Tuning for SSD/HDD
- **Kernel Parameters**: sysctl optimization
- **Filesystem**: mount options, alignment
- **CPU Affinity**: Pinning ships to cores

### 2. Ship-Level
- **|pack/|meld**: Scheduling and deduplication
- **Loom Sizing**: Memory allocation for ships
- **App Suspension**: Disabling resource-heavy agents
- **State Management**: Reducing pier bloat

### 3. Infrastructure
- **Storage Selection**: SSD type, IOPS, capacity
- **Network Tuning**: TCP buffers, BBR, firewall
- **Resource Allocation**: CPU cores, RAM limits
- **Monitoring**: Metrics collection, alerting

### 4. Application
- **Gall Agent Optimization**: Efficient state structures
- **Caching Strategies**: In-memory hot data
- **Streaming**: Processing large data incrementally
- **Jet Utilization**: Using accelerated stdlib

## Bottleneck Identification

### Disk I/O Bottleneck

**Symptoms**:
- `iowait%` >20% (sustained)
- Slow |pack completion (>5 minutes for 5GB pier)
- Lag in dojo responsiveness
- High disk I/O in monitoring

**Diagnostic**:
```bash
iostat -x 5  # Check %util, await, svctm
iotop -oP  # Identify I/O-heavy processes
df -h /path/to/pier  # Disk space
```

**Resolutions** (ordered by effectiveness):
1. **Upgrade to NVMe SSD**: 10x-100x improvement over HDD
2. **I/O scheduler**: `echo "none" > /sys/block/nvme0n1/queue/scheduler`
3. **Filesystem**: Add `noatime,nodiratime` to `/etc/fstab`
4. **Run |pack**: Defragments pier, reduces I/O load
5. **Reduce ship count**: Distribute ships across servers

### CPU Bottleneck

**Symptoms**:
- Sustained >80% CPU usage
- Slow event processing
- Delayed |pack/|meld completion
- High load average (>4 for quad-core)

**Diagnostic**:
```bash
top  # Check CPU usage per process
htop  # Visualize CPU distribution
# In dojo:
|mass  # Memory and CPU breakdown
```

**Resolutions**:
1. **Suspend unused apps**: `|suspend %app-name` in dojo
2. **Increase CPU priority**: Add `Nice=-10` in systemd `[Service]`
3. **CPU affinity**: `CPUAffinity=0-3` in systemd `[Service]`
4. **Upgrade CPU**: Faster clock speed (single-thread performance critical)
5. **Distribute ships**: Move to additional servers

### Memory Bottleneck

**Symptoms**:
- "out of loom" errors (memory limit exceeded)
- Frequent |pack needed (weekly or daily)
- OOM kills (system RAM exhaustion)
- Swap usage >50%

**Diagnostic**:
```bash
free -h  # Check available RAM
# In dojo:
|mass  # Memory usage breakdown per app
```

**Resolutions**:
1. **Run |meld**: Deduplication requires 8GB+ RAM during execution
2. **Increase loom**: `--loom 32` (4GB) or `--loom 33` (8GB)
3. **Suspend memory-heavy apps**: Identify with |mass
4. **Upgrade system RAM**: 8GB minimum for comfortable operation
5. **Weekly |pack**: Preventive maintenance (reduces memory fragmentation)

### Network Bottleneck

**Symptoms**:
- Slow Ames communication (subscriptions delay >30s)
- Delayed message delivery
- High network latency
- Packet loss

**Diagnostic**:
```bash
ping -c 100 8.8.8.8  # Check latency
iftop  # Monitor bandwidth usage
# In dojo:
|hi ~zod  # Test Ames connectivity
# Check firewall:
sudo ufw status
```

**Resolutions**:
1. **Firewall**: Verify UDP 34543 open: `sudo ufw allow 34543/udp`
2. **TCP tuning**: Increase buffer sizes in `/etc/sysctl.conf`
3. **Bandwidth**: Upgrade VPS plan if saturated
4. **Geographic proximity**: Deploy VPS closer to users
5. **BBR congestion control**: `net.ipv4.tcp_congestion_control=bbr`

## Performance Tuning

### Essential Tuning

#### SSD Storage
```
Type: NVMe preferred
I/O Scheduler: none (for NVMe), deadline (for SATA SSD)
Mount Options: noatime,nodiratime
Alignment: 4K sectors (align with SSD blocks)
```

#### Filesystem
```bash
# /etc/fstab
/dev/nvme0n1p1 /path/to/pier ext4 defaults,noatime,nodiratime 0 0
```

#### Kernel Parameters
```bash
# /etc/sysctl.conf
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_congestion_control = bbr
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 3
```

#### Loom Sizing
```bash
# 4GB RAM: --loom 32
# 8GB+ RAM: --loom 33
urbit --loom 32 /path/to/pier
```

#### CPU Priority
```ini
# systemd service file
[Service]
Nice=-10
# For multi-core:
CPUAffinity=0-3
```

### Preventive Maintenance

#### Weekly |pack
```bash
# cron: 0 2 * * 0 (2 AM every Sunday)
/path/to/urbit -F /path/to/pier/.urb/put | pack &
```

#### Monthly |meld (8GB+ RAM only)
```bash
# cron: 0 3 1 * * (3 AM on 1st of month)
/path/to/urbit -F /path/to/pier/.urb/put | meld &
```

#### Automated Backup
```bash
# cron: 0 4 * * * (4 AM daily)
#!/bin/bash
DATE=$(date +%Y%m%d)
urbit -I 30 /path/to/pier/.urb/put | pack &
# Wait for ship to stop
tar -czf /backup/pier-${DATE}.tar.gz /path/to/pier
urbit /path/to/pier &
```

## Capacity Planning

### Growth Projections

```bash
# Calculate monthly pier growth
CURRENT=$(du -sb /path/to/pier | awk '{print $1}')
PREVIOUS=$(cat /var/log/pier-size-30d-ago.txt)
GROWTH=$((CURRENT - PREVIOUS))
MONTHLY_GROWTH_GB=$((GROWTH / 1073741824))

echo "Monthly growth: ${MONTHLY_GROWTH_GB}GB"

# Project remaining capacity
DISK_FREE=$(df /path/to/pier | tail -1 | awk '{print $4}')
MONTHS_REMAINING=$((DISK_FREE / GROWTH))
echo "Months until disk full: $MONTHS_REMAINING"
```

### Scaling Triggers

**Vertical scaling** (upgrade current VPS):
- RAM utilization >80% for 7+ days
- Disk >85% full
- CPU >80% sustained
- Response time >2s (95th percentile)

**Horizontal scaling** (add servers):
- Managing 10+ ships on single VPS
- Need geographic distribution
- Need to isolate critical vs non-critical ships
- Single point of failure concern

## SLA Targets

### Availability
- **Target**: 99.9% uptime (8.76 hours downtime/year)
- **Measurement**: `uptime`, systemd logs, external monitoring
- **Improvements**: Automated monitoring, alerting, redundancy, failover

### Response Time
- **Target**: Dojo command response <1 second (95th percentile)
- **Measurement**: Manual testing, custom instrumentation, monitoring dashboards
- **Improvements**: |pack, SSD upgrade, RAM increase, app optimization

### Pier Size Growth
- **Target**: <10GB growth per month for typical ship
- **Measurement**: `du -sh /path/to/pier` (tracked weekly)
- **Improvements**: |pack (weekly), |meld (monthly), app cleanup, state migration

## Monitoring Setup

### Prometheus Node Exporter
```bash
# Install node exporter
curl -fsSL https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz | tar xz
cd node_exporter-1.6.1.linux-amd64
./node_exporter --web.listen-address=:9100
```

### Ship Metrics
```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'urbit-ship'
    static_configs:
      - targets: ['localhost:9100']
    metrics_path: '/metrics'
```

### Grafana Dashboard
- **CPU Usage**: System-wide and per-process
- **Memory Usage**: System RAM, loom usage, swap
- **Disk I/O**: %util, await, svctm, read/write rates
- **Network**: Bandwidth, latency, packet loss
- **Ship-specific**: Pier size, event throughput, agent state

## Best Practices

1. **Measure first**: Establish baseline before optimizing
2. **One change at a time**: Isolate what improves performance
3. **SSD mandatory**: HDD too slow for production Urbit
4. **Preventive |pack**: Weekly automation prevents emergencies
5. **Monitor trends**: Track pier size, CPU, RAM over time
6. **Document changes**: Record all tuning parameters in config files
7. **Test thoroughly**: Verify ship functionality after changes
8. **Plan capacity**: Scale before hitting limits (not after)
9. **Automate maintenance**: Cron jobs for |pack, backups, monitoring
10. **Hardware > software**: Sometimes upgrading hardware is better than optimization

## Performance Optimization Checklist

### Storage
- [ ] NVMe SSD (or high-quality SATA SSD)
- [ ] I/O scheduler: 'none' for NVMe, 'deadline' for SATA
- [ ] Filesystem: noatime,nodiratime options
- [ ] Adequate disk space: <85% usage

### Memory
- [ ] 8GB+ RAM (recommended)
- [ ] Loom sized: --loom 32 (4GB) or --loom 33 (8GB+)
- [ ] Weekly |pack scheduled
- [ ] Monthly |meld (if 8GB+ RAM)
- [ ] Swap: swappiness=10 (or disabled if 8GB+)

### CPU
- [ ] Appropriate CPU: >=2 cores recommended
- [ ] Nice=-10 for urbit service
- [ ] CPU affinity: Pin to specific cores
- [ ] Unused apps suspended via |mass

### Network
- [ ] Firewall: UDP 34543 open
- [ ] TCP tuning: rmem_max, wmem_max, congestion_control
- [ ] Geographic proximity: VPS near users
- [ ] Adequate bandwidth: Monitor saturation

### Monitoring
- [ ] Prometheus node exporter installed
- [ ] Grafana dashboard configured
- [ ] Alerting rules configured
- [ ] Weekly capacity projections reviewed
- [ ] SLA targets documented

## Resources

- [Performance Optimization](../performance-optimization/SKILL.md)
- [Performance Profiling](../performance-profiling/SKILL.md)
- [Monitoring Observability](../monitoring-observability/SKILL.md)
- [SLA Management](../sla-management/SKILL.md)
- [Urbit Operators Manual](https://operators.urbit.org)

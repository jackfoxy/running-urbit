---
name: backup-disaster-recovery
description: Comprehensive backup strategies and recovery procedures for Urbit ships including automated backups, 3-2-1 backup rule, safe pier backup procedures, recovery testing, and business continuity planning. Use when implementing backups, planning disaster recovery, recovering from failures, or ensuring data protection.
user-invocable: true
disable-model-invocation: false
validated: safe
checked-by: ~sarlev-sarsen
notes: Some data recovery is possible with the Tlon app. Further improvement to this skill required to handle the nature of Urbit's backup and recovery story.
---

# Backup and Disaster Recovery Skill

Comprehensive backup strategies, recovery procedures, and business continuity planning for Urbit ship deployments.

## Overview

Effective backup and disaster recovery ensures ship availability, data protection, and rapid recovery from failures including hardware failures, data corruption, and operational errors.

## Critical Backup Principles

### 1. NEVER Backup Live Piers

**CRITICAL**: Backing up a running ship corrupts the event log

**Safe Backup Procedure**:
```bash
# 1. Stop ship gracefully
# In dojo: ctrl+d
# Or: systemctl stop urbit-ship

# 2. Wait for complete shutdown
sleep 30

# 3. Verify ship stopped
ps aux | grep urbit  # Should show nothing

# 4. Backup pier
tar czf ship-backup-$(date +%Y%m%d).tar.gz /path/to/pier

# 5. Restart ship
urbit /path/to/pier
# Or: systemctl start urbit-ship
```

### 2. 3-2-1 Backup Rule

- **3** copies of data (original + 2 backups)
- **2** different storage types (local disk + cloud)
- **1** offsite backup (different geographic location)

### 3. Test Restorations Quarterly

Untested backups = no backups

## Automated Backup Script

```bash
# /usr/local/bin/urbit-backup.sh
#!/bin/bash
set -euo pipefail

# Configuration
SHIP_NAME="sampel-palnet"
PIER_PATH="/home/urbit/$SHIP_NAME"
BACKUP_DIR="/backups/urbit"
DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="$BACKUP_DIR/$SHIP_NAME-$DATE.tar.gz"
RETENTION=7  # Keep last 7 backups
LOG_FILE="/var/log/urbit-backup.log"

# Logging
exec > >(tee -a "$LOG_FILE")
exec 2>&1

echo "=== Urbit Backup Started: $(date) ==="

# Step 1: Stop ship gracefully
echo "Stopping ship..."
systemctl stop urbit-$SHIP_NAME

# Step 2: Wait for complete shutdown
echo "Waiting for ship to stop..."
sleep 30

# Step 3: Verify ship stopped
if pgrep -f "urbit.*$SHIP_NAME" > /dev/null; then
    echo "ERROR: Ship still running! Aborting backup."
    systemctl start urbit-$SHIP_NAME
    exit 1
fi

# Step 4: Create backup
echo "Creating backup..."
tar czf "$BACKUP_FILE" -C "$(dirname "$PIER_PATH")" "$(basename "$PIER_PATH")"

# Step 5: Verify backup integrity
echo "Verifying backup..."
if ! tar tzf "$BACKUP_FILE" > /dev/null; then
    echo "ERROR: Backup verification failed!"
    rm -f "$BACKUP_FILE"
    systemctl start urbit-$SHIP_NAME
    exit 1
fi

# Step 6: Restart ship
echo "Restarting ship..."
systemctl start urbit-$SHIP_NAME

# Step 7: Verify ship started
sleep 10
if ! systemctl is-active --quiet urbit-$SHIP_NAME; then
    echo "ERROR: Ship failed to restart!"
    exit 1
fi

# Step 8: Cleanup old backups
echo "Cleaning up old backups (keeping last $RETENTION)..."
ls -t $BACKUP_DIR/$SHIP_NAME-*.tar.gz | tail -n +$((RETENTION + 1)) | xargs -r rm -f

# Step 9: Report
BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
echo "Backup completed: $BACKUP_FILE ($BACKUP_SIZE)"

# Step 10: Offsite backup (optional)
# aws s3 cp "$BACKUP_FILE" s3://urbit-backups/

echo "=== Backup Finished: $(date) ==="
```

```bash
# Make executable
chmod +x /usr/local/bin/urbit-backup.sh

# Schedule via cron (weekly: Sunday 3 AM)
sudo crontab -e
0 3 * * 0 /usr/local/bin/urbit-backup.sh
```

## Offsite Backup Options

### AWS S3

```bash
# Install AWS CLI
sudo apt install awscli -y

# Configure credentials
aws configure

# Upload backup
aws s3 cp "$BACKUP_FILE" s3://urbit-backups/$(date +%Y/%m/%d)/

# Lifecycle policy (delete >90 days)
aws s3api put-bucket-lifecycle-configuration --bucket urbit-backups --lifecycle-configuration file://lifecycle.json
```

```json
{
  "Rules": [{
    "Id": "DeleteOldBackups",
    "Status": "Enabled",
    "Prefix": "",
    "Expiration": { "Days": 90 }
  }]
}
```

### Backblaze B2 (Cost-Effective)

```bash
# Install B2 CLI
sudo pip3 install b2

# Authorize account
b2 authorize-account <application-key-id> <application-key>

# Upload
b2 upload-file urbit-backups "$BACKUP_FILE" "$(basename $BACKUP_FILE)"
```

### Rsync to Remote Server

```bash
# Sync backups to remote server
rsync -avz --delete $BACKUP_DIR/ backup-server:/backups/urbit/

# Over SSH with compression
rsync -avz -e "ssh -p 2222" $BACKUP_DIR/ user@backup-server:/backups/
```

## Recovery Procedures

Recovery of Urbit ships from a full pier backup is currently unsupported. Some applications, such as Tlon Messenger, may support backup and recovery of application state, but given Urbit's stateful networking model and current tooling, if an copy of a pier is used that does not have the most up to date state, it will be unable to network with peers across the network. While you will not be able to network with peers from an out-of-date backup, you can boot with the `-L` or `--local` flag to run in offline mode. In this mode, you can run without ames networking and manually retrieve any vital data out of your ship. 

In order to regain networking, you will need to perform a 'network breach' or factory reset. This will create a fresh instance of your ship without any data. You can then try to manually recover the application state that you may have lost.

## Failure Scenarios

### Scenario 1: Hardware Failure (Total Loss)

**Recovery Steps**:
1. Factory Reset (aka 'breach')

### Scenario 2: Pier Corruption

**Recovery Steps**:
1. Attempt event replay: `./urbit replay pier/`
3. If replay fails, factory reset (will result in data loss)

**RTO**: 30 minutes
**RPO**: Last backup

### Scenario 3: Accidental Deletion

**Recovery Steps**:
1. Factory Reset (aka 'breach')

### Scenario 4: Keyfile Loss (Planet)

**Impact**: Cannot factory reset without keyfile

**Prevention**:
- **Master ticket**: Store securely offline (password manager, paper wallet)
- **Master ticket = recovery**: Can generate new keyfile via Bridge
- **NEVER store keyfile after first boot** (consumed, useless)

**Recovery**:
1. Access Bridge with master ticket
2. Perform factory reset (generates NEW keyfile)
3. Boot fresh ship with new keyfile
4. WARNING: All groups/channels/messages lost (no data recovery)

### Scenario 5: Comet Loss

**Impact**: Comet = pier (no identity recovery)

**Prevention**:
- Comets should be used for empheral identities.

**Recovery**:
- Because comets cannot do key rotation, an urbit ship with a comet identity that gets into a bad networking state is permanently lost, generate new (different identity)

## GroundSeg Multi-Ship Backup

If running your ship with Groundseg and Native Planet's Startram service, they offer automatic encrypted backups of your Tlon Messenger state. Contact support@nativeplanet.io for help if you encounter data loss for your Startram enabled ships.

## Backup Verification

### Integrity Check

```bash
# Verify backup file integrity
tar tzf backup.tar.gz > /dev/null && echo "Backup valid" || echo "Backup corrupted"
```

### Test Restoration (Quarterly)

```bash
# Create test environment
mkdir /tmp/restore-test

# Extract backup
tar xzf backup.tar.gz -C /tmp/restore-test

# Attempt boot (dry-run)
urbit /tmp/restore-test/pier --dry-run

# Cleanup
rm -rf /tmp/restore-test
```

## Business Continuity Planning

### Documentation Requirements

1. **Recovery procedures**: Step-by-step restoration guide
2. **Contact information**: On-call admin, vendor support
3. **Access credentials**: Stored securely (password manager)
4. **Backup locations**: Where backups stored (local, offsite)
5. **RTO/RPO targets**: Defined for each failure scenario

### Maintenance Schedule

- **Daily**: Automated backup execution
- **Weekly**: Verify backup success (check logs)
- **Monthly**: Review backup size trends, cleanup old backups
- **Quarterly**: Test restoration procedure, update documentation
- **Annually**: Review disaster recovery plan, update procedures

## Best Practices Checklist

- [ ] Backups stop ship before creation (never live)
- [ ] Backup verification (tar tzf) succeeds
- [ ] Offsite storage configured (S3/B2/rsync)
- [ ] 3-2-1 rule implemented
- [ ] Retention policy: 4 weekly, 12 monthly
- [ ] Master ticket stored securely offline
- [ ] Recovery procedures documented
- [ ] Quarterly restoration tests scheduled
- [ ] Monitoring backup success (log analysis, alerts)
- [ ] RTO/RPO targets defined
- [ ] Team trained on recovery procedures

## Common Mistakes to Avoid

1. **Backing up live pier**: Corrupts event log (always stop first)
2. **No offsite backups**: Single point of failure
3. **Untested restorations**: Backups may be invalid if from a previous networking state
4. **Storing keyfile after boot**: Security risk, useless
5. **No master ticket backup**: Cannot factory reset planet without private keys
6. **Insufficient retention**: Can't recover from discovered corruption
7. **No monitoring**: Backup failures go unnoticed
8. **Weak access controls**: Backup credentials compromised
9. **No documentation**: Recovery delayed, errors made
10. **No testing**: Recovery procedures fail when needed

## Reference

- Urbit backup guide: https://docs.urbit.org/manual/os/ship-troubleshooting
- AWS S3 CLI: https://docs.aws.amazon.com/cli/latest/userguide/cli-services-s3.html
- Backblaze B2: https://www.backblaze.com/b2/docs/

## Summary

URBIT'S BACKUP AND RECOVERY STORY IS STILL NASCENT. BECAUSE OF URBIT'S STATEFUL NETWORKING AND NATURE AS A DETERMINISTIC OPERATING FUNCTION, BACKUP AND RECOVERY IS NOT AS SIMPLE AS KEEPING ADDITIONAL OLD COPIES OF YOUR URBIT PIER AND REBOOTING FROM AN OLDER STATE. REBOOTING FROM AN OLDER STATE SHOULD ONLY BE DONE WITH AMES NETWORKING DISABLED. Effective Urbit backup requires stopping ships before backup (never backup live piers), implementing 3-2-1 rule (3 copies, 2 media types, 1 offsite), automated scheduling (weekly via cron), backup verification (tar integrity check), and quarterly restoration testing. Recovery procedures vary by disaster scenario (hardware failure, pier corruption, keyfile loss, comet loss) with defined RTO/RPO targets. Master tickets must be stored securely offline for planet recovery. GroundSeg deployments require multi-ship backup orchestration. Document all procedures, monitor backup success, and test restorations regularly.

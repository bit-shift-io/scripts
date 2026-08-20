#!/bin/bash
set -euo pipefail

# systemd timeouts and journald log size

sudo install -d /etc/systemd/system.conf.d /etc/systemd/journald.conf.d

# faster shutdown / startup timeouts
sudo tee /etc/systemd/system.conf.d/50-timeouts.conf > /dev/null <<'EOF'
[Manager]
DefaultTimeoutStartSec=5s
DefaultTimeoutStopSec=5s
EOF

# cap logs at 50mb
sudo tee /etc/systemd/journald.conf.d/50-size.conf > /dev/null <<'EOF'
[Journal]
SystemMaxUse=50M
EOF

echo "Done!"
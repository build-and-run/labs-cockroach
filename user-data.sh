#!/bin/bash

set -eo 'pipefail'
exec > /var/log/user-data.log 2>&1

export DEBIAN_FRONTEND=noninteractive

apt-get update -yqq
apt-get upgrade -yqq
apt-get install -yqq chrony
echo "server 169.254.169.123 prefer iburst" > /etc/chrony.conf
service chrony restart
chronyc sources -v
chronyc tracking

# install cockroachDB
cd /tmp
wget -qO- https://binaries.cockroachdb.com/cockroach-v1.1.4.linux-amd64.tgz | tar  xvz
cp -i cockroach-v1.1.4.linux-amd64/cockroach /usr/local/bin

# start cockroach
cat << _EOF_ > /usr/local/bin/start-cockroach
#!/bin/bash

exec cockroach start \
  --join http-lb=eu.cockroachdb.streax.io \
  --cache 25% \
  --max-sql-memory 25% \
  --background
_EOF_
chmod a+x /usr/local/bin/start-cockroach

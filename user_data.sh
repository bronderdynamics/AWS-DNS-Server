#!/bin/bash
# Install and configure BIND9

# Update system
dnf update -y

# Install BIND9
dnf install -y bind bind-utils

# Backup original config
cp /etc/named.conf /etc/named.conf.backup

# Configure BIND
cat > /etc/named.conf <<'EOF'
options {
    listen-on port 53 { any; };
    listen-on-v6 port 53 { any; };
    directory       "/var/named";
    dump-file       "/var/named/data/cache_dump.db";
    statistics-file "/var/named/data/named_stats.txt";
    memstatistics-file "/var/named/data/named_mem_stats.txt";
    
    allow-query { localnets; };
    
    recursion yes;
    allow-recursion { localnets; };
    
    auth-nxdomain no;
    
    forwarders {
        169.254.169.253;
    };
    
    dnssec-validation yes;
    
    managed-keys-directory "/var/named/dynamic";
    
    pid-file "/run/named/named.pid";
    session-keyfile "/run/named/session.key";
};

logging {
    channel default_debug {
        file "data/named.run";
        severity dynamic;
    };
};

zone "." IN {
    type hint;
    file "named.ca";
};

zone "${dns_domain}" IN {
    type master;
    file "/var/named/${dns_domain}.zone";
    allow-update { none; };
};

zone "0.10.in-addr.arpa" IN {
    type master;
    file "/var/named/0.10.in-addr.arpa.zone";
    allow-update { none; };
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";
EOF

# Create zone file
cat > /var/named/${dns_domain}.zone <<EOF
\$TTL 86400
@   IN  SOA     ns1.${dns_domain}. admin.${dns_domain}. (
            2024121201
            3600
            1800
            604800
            86400 )

    IN  NS      ns1.${dns_domain}.
    IN  NS      ns2.${dns_domain}.
    IN  NS      ns3.${dns_domain}.

ns1 IN  A       10.0.1.10
ns2 IN  A       10.0.2.10
ns3 IN  A       10.0.3.10

server${server_id} IN TXT "DNS Server ${server_id}"
EOF

# Create reverse zone
cat > /var/named/0.10.in-addr.arpa.zone <<'EOF'
$TTL 86400
@   IN  SOA     ns1.${dns_domain}. admin.${dns_domain}. (
            2024121201
            3600
            1800
            604800
            86400 )

    IN  NS      ns1.${dns_domain}.
EOF

# Set permissions
chown -R named:named /var/named
chmod 640 /var/named/${dns_domain}.zone
chmod 640 /var/named/0.10.in-addr.arpa.zone

# Start BIND
systemctl enable named
systemctl start named

# Configure firewall
firewall-cmd --permanent --add-service=dns
firewall-cmd --reload

echo "DNS server setup complete"


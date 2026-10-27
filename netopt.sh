#!/bin/bash
# v2ray VPS network tuning - BBR + buffers + tunnel-friendly
CONF=/etc/sysctl.d/99-net-tuning.conf
cat > $CONF <<'EOF'
# BBR congestion control
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
# socket buffers (TCP + UDP, mKCP 受益)
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.core.rmem_default=262144
net.core.wmem_default=262144
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216
net.ipv4.tcp_slow_start_after_idle=0
# 6in4 隧道友好：关闭反向路径过滤，防丢"martian"包
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
# MTU 探测，防路径 MTU 黑洞
net.ipv4.tcp_mtu_probing=1
# 队列
net.core.netdev_max_backlog=16384
net.core.optmem_max=65536
EOF
sysctl --system >/dev/null
# 给现有网卡应用 fq（BBR 依赖）
for dev in $(ls /sys/class/net | grep -v '^lo$'); do tc qdisc replace dev "$dev" root fq 2>/dev/null; done
echo "==== 验证 ===="
sysctl net.ipv4.tcp_congestion_control net.core.default_qdisc net.ipv4.conf.all.rp_filter
tc qdisc show dev $(ls /sys/class/net | grep -v '^lo$' | head -1) | head -1
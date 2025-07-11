sudo dnf config-manager --set-enabled crb
sudo dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm -y
sudo dnf clean all
sudo dnf makecache 
sudo grubby --update-kernel=ALL --args="systemd.unified_cgroup_hierarchy=1 systemd.legacy_systemd_cgroup_controller=0 cgroup_no_v1=all"
sudo grub2-mkconfig -o /boot/efi/EFI/rocky/grub.cfg
sudo grub2-mkconfig -o /boot/grub2/grub.cfg

sudo ls /boot/grub2/
cat /etc/hosts
ip a

# 修改mariadb源
sudo timedatectl set-timezone Asia/Shanghai
sudo curl -LsS https://r.mariadb.com/downloads/mariadb_repo_setup | bash
## 效果应该就是下边这样
sudo vi /etc/yum.repos.d/mariadb.repo
[mariadb-main]
name = MariaDB Server
baseurl = https://dlm.mariadb.com/repo/mariadb-server/11.rolling/yum/rhel/9/x86_64
gpgkey = file:///etc/pki/rpm-gpg/MariaDB-Server-GPG-KEY
gpgcheck = 1
enabled = 1
module_hotfixes = 1


[mariadb-maxscale]
# To use the latest stable release of MaxScale, use "latest" as the version
# To use the latest beta (or stable if no current beta) release of MaxScale, use "beta" as the version
name = MariaDB MaxScale
baseurl = https://dlm.mariadb.com/repo/maxscale/latest/yum/rhel/9/x86_64
gpgkey = file:///etc/pki/rpm-gpg/MariaDB-MaxScale-GPG-KEY
gpgcheck = 1
enabled = 1


[mariadb-tools]
name = MariaDB Tools
baseurl = https://downloads.mariadb.com/Tools/rhel/9/x86_64
gpgkey = file:///etc/pki/rpm-gpg/MariaDB-Enterprise-GPG-KEY
gpgcheck = 1
enabled = 1

# 安装
sudo dnf install mariadb-server
sudo dnf install -y  MariaDB-devel

sudo dnf group install "Development Tools" -y
sudo dnf update
sudo dnf install yum-utils -y
# 启用crb源
sudo dnf config-manager --set-enabled crb
sudo dnf install epel-release -y
sudo dnf install epel-next-release -y
sudo dnf update -y

# 修改hostname
sudo hostnamectl set-hostname admin
sudo hostnamectl set-hostname compute-01

cat /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
192.168.50.15	compute-01

# 关闭selinux
#sudo vi /etc/selinux/config
sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
sudo systemctl stop firewalld.service
sudo systemctl disable firewalld.service
sudo reboot

sudo dnf clean all
sudo dnf makecache

sudo grub2-mkconfig -o /boot/grub2/grub.cfg



# 客户端和服务端 
#sudo dnf install MariaDB-server MariaDB-devel

sudo dnf install MariaDB-client MariaDB-devel

sudo dnf list mariadb-devel --showduplicates
sudo dnf install MariaDB-devel-11.8.2-1.el9.x86_64

# 从服务端复制GPG-key（不确定是不是需要这样）
sudo scp /etc/pki/rpm-gpg/MariaDB-Server-GPG-KEY root@192.168.50.138:/etc/pki/rpm-gpg/

sudo dnf config-manager --set-enabled crb

sudo dnf install python3 gcc openssl openssl-devel pam-devel numactl numactl-devel hwloc lua readline-devel ncurses-devel man2html libibmad libibumad perl-ExtUtils-MakeMaker.noarch
sudo dnf install make rrdtool-devel lua-devel hwloc-devel rpm-build

sudo dnf install munge-devel munge-libs

mkdir -p $HOME/slurm-tmp && cd $HOME/slurm-tmp

wget --no-check-certificate "https://download.schedmd.com/slurm/slurm-24.05.2.tar.bz2"

# rpmbuild -ta "$LSURM_TAR" --define '_ito_cflags %{ni}' --with mysql
rpmbuild -ta slurm-24.05.2.tar.bz2

cd ~/rpmbuild/RPMS/x86_64
sudo dnf install slurm-24.05.2-1.el9.x86_64.rpm
sudo dnf install slurm-perlapi-24.05.2-1.el9.x86_64.rpm
# sudo dnf install slurm-slurmctld-24.05.2-1.el9.x86_64.rpm # 管理端才需要
sudo dnf install slurm-slurmdbd-24.05.2-1.el9.x86_64.rpm
sudo dnf install slurm-slurmd-24.05.2-1.el9.x86_64.rpm

CLUSTER_NAME=Cnode_all
echo $CLUSTER_NAME

get_hardware_info(){
    local cpus=$(nproc)
    local sockets=$(lscpu | grep 'Socket(s)' | awk '{print $2}')
    local cores_per_socket=$(lscpu | grep 'Core(s) per socket' | awk '{print $4}')
    local threads_per_core=$(lscpu | grep 'Thread(s) per core' | awk '{print $4}')
    local real_memory=$(free -m | awk '/Mem:/ {print $2}')
    echo "$cpus $sockets $cores_per_socket $threads_per_core $real_memory"
}

read cpus sockets cores_per_socket threads_per_core real_memory <<< $(get_hardware_info)
start_num=$(echo "${compute_hostnames[0]}" | grep -o '[0-9]\+$')
end_num=$(echo "${compute_hostnames[-1]}" | grep -o '[0-9]\+$')
node_rang="${prefix}[${start_num}-{end_num}]"

sudo mkdir -p /etc/slurm

LOG_DIR="/var/log/slurm"
SPOOL_DIR="/var/spool/slurm"

# 这个也许适用于服务端
sudo mkdir -p "$SPOOL_DIR/slurmd" \
"$SPOOL_DIR/slurmctld" \
"$SPOOL_DIR/cluster_state" \
"$LOG_DIR"
sudo touch "$LOG_DIR/slurmctld.log" \
"$LOG_DIR/slurm_jobacct.log" \
"$LOG_DIR/slurm_jobcomp.log"

sudo chown -R slurm:slurm /etc/slurm
sudo chmod 600 /etc/slurm/slurmdbd.conf
sudo chown slurm:slurm /var/spool/slurm/slurmd
sudo chmod 755 /var/spool/slurm/slurmd
sudo chown slurm:slurm /var/spool/slurm/slurmctld
sudo chmod 755 /var/spool/slurm/slurmctld
sudo chown slurm:slurm /var/spool/slurm/cluster_state
sudo chown slurm:slurm /var/log/slurm/
sudo chmod 755 /var/log/slurm/
sudo chown slurm:slurm /var/log/slurm/slurmctld.log
sudo chown slurm: /var/log/slurm/slurm_jobacct.log /var/log/slurm/slurm_jobcomp.log
sudo chmod 777 /var/spool/slurm

OSVERSION=""
OSDISTRO=""
OSARCH=""
NODE_ROLE=""
ISOSREADHAT="false"
SUPPORTED_DISTROS="Centos, Rocky Linux and Almalinux: 8, 9 and 10; Ubuntu: 18.04, 20.04, 22.04 and 24.04; Amazon Linux: 2023."
slurm_accounting_support=0
random_mysql_password=$(tr -dc '0-9a-zA-Z@' < /dev/urandom | head -c 20)
StoragePass=$random_mysql_password
StorageType=accounting_storage/mysql
DbdHost=localhost
StorageHost=$DbdHost
StorageLoc=slurm_acct_db
JobCompLoc=slurm_jobcomp_db
StorageUser=slurm
SlurmUser=$StorageUser
StoragePort=3306
without_interaction="false"
mysql_root_password=""
without_interaction_parameter="false"

echo $StoragePass # WKOyegu3b5lMXAoXJrRm

vi slurm.config

# 这些可能也是服务端用的
sudo mysql -u root -e "CREATE DATABASE $StorageLoc;"
sudo mariadb -u root -e "CREATE DATABASE $StorageLoc;"

cat <<EOF | sudo tee /etc/slurm/slurmdbd.conf
AuthType=auth/munge
AuthInfo=/var/run/munge/munge.socket.2
DbdHost=$DbdHost
DbdAddr=127.0.0.1
DbdPort=6819
SlurmUser=$SlurmUser
MessageTimeout=60
DebugLevel=debug5
DefaultQOS=normal
LogFile=/var/log/slurm/slurmdbd.log
PidFile=/var/run/slurmdbd.pid
StorageType=$StorageType
StorageHost=$StorageHos
StorageLoc=$StorageLoc
StoragePort=$StoragePort
StorageUser=$StorageUser
StoragePass=$StoragePass
EOF

# 配置mysql，这个应该也是服务端
mysql
create user 'slurm'@'localhost' identified by 'IyZmCmDgthPEnxQQmO6g'; #n8vRYNctxnNWdD8u4giy
create database slurm_acct_db;
grant all on slurm_acct_db.* TO 'slurm'@'localhost' identified by 'IyZmCmDgthPEnxQQmO6g' with grant option;
create database slurm_jobcomp_db;
grant all on slurm_jobcomp_db.* TO 'slurm'@'localhost' identified by 'IyZmCmDgthPEnxQQmO6g' with grant option;
FLUSH PRIVILEGES;
show databases;
exit;

total_memory=$(free -m | awk '/^Mem:/{print $2}')
echo $total_memory # 112224
innodb_buffer_percent=50
innodb_buffer_pool_size=$((total_memory * innodb_buffer_percent / 100))
echo $innodb_buffer_pool_size # 56112

cat <<EOF | sudo tee /etc/my.cnf.d/slurm.cnf 
[mariadb]
innodb_lock_wait_timeout=900
innodb_log_file_size=128M
max_allowed_packet=32M
innodb_buffer_pool_size=${innodb_buffer_pool_size}M
EOF

sudo systemctl restart mariadb

sudo chown -R slurm:slurm /etc/slurm
sudo chmod 600 /etc/slurm/slurmdbd.conf
sudo chown slurm:slurm /var/spool/slurm/slurmd
sudo chmod 755 /var/spool/slurm/slurmd
sudo chown slurm:slurm /var/spool/slurm/slurmctld
sudo chmod 755 /var/spool/slurm/slurmctld
sudo chown slurm:slurm /var/spool/slurm/cluster_state
sudo chown slurm:slurm /var/log/slurm/
sudo chmod 755 /var/log/slurm/
sudo chown slurm:slurm /var/log/slurm/slurmctld.log
sudo chown slurm: /var/log/slurm/slurm_jobacct.log /var/log/slurm/slurm_jobcomp.log
sudo chmod 777 /var/spool/slurm

slurmctld_service="/lib/systemd/system/slurmctld.service"
slurmd_service="/lib/systemd/system/slurmd.service"
cat $slurmctld_service
conf_server_port="${admin:-6817}"
sudo sed -i '/^After=network-online.target remote-fs.target munge.service sssd.service$/ s/$/ slurmdbd.service/' "$slurmctld_service"
cat "$slurmctld_service"

sudo vim "$slurmd_service"
sudo vim /lib/systemd/system/slurmd.service
cat <<EOF | sudo tee /lib/systemd/system/slurmd.service
[Unit]
Description=Slurm node daemon
After=munge.service network-online.target remote-fs.target sssd.service
Wants=network-online.target
#ConditionPathExists=/etc/slurm/slurm.conf

[Service]
Type=notify
EnvironmentFile=-/etc/sysconfig/slurmd
EnvironmentFile=-/etc/default/slurmd
RuntimeDirectory=slurm
RuntimeDirectoryMode=0755
ExecStart=/usr/sbin/slurmd --systemd --conf-server admin:6817 $SLURMD_OPTIONS
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
LimitNOFILE=131072
LimitMEMLOCK=infinity
LimitSTACK=infinity
Delegate=yes
TasksMax=infinity

# Uncomment the following lines to disable logging through journald.
# NOTE: It may be preferable to set these through an override file instead.
#StandardOutput=null
#StandardError=null

[Install]
WantedBy=multi-user.target
EOF

cat /etc/hosts

sudo systemctl daemon-reload
sudo systemctl enable --now slurmdbd
sudo systemctl enable --now slurmctld
sudo systemctl enable slurmd
sudo systemctl enable mariadb

sudo systemctl restart mariadb
sudo systemctl restart slurmdbd.service
sudo systemctl restart slurmctld.service
sudo systemctl restart slurmd.service

# 设置这几个服务的内容，保持顺序
## 修改
/etc/systemd/system/slurmctld.service
[Unit]
Description=Slurm controller daemon
After=network-online.target remote-fs.target munge.service sssd.service slurmdbd.service
Wants=network-online.target
ConditionPathExists=/etc/slurm/slurm.conf

[Service]
Type=simple
EnvironmentFile=-/etc/sysconfig/slurmctld
EnvironmentFile=-/etc/default/slurmctld
ExecStart=/usr/sbin/slurmctld -D -s $SLURMCTLD_OPTIONS
ExecReload=/bin/kill -HUP $MAINPID
LimitNOFILE=65536
TasksMax=infinity

# Uncomment the following lines to disable logging through journald.
# NOTE: It may be preferable to set these through an override file instead.
#StandardOutput=null
#StandardError=null

[Install]
WantedBy=multi-user.target


## 修改
sudo vim /etc/systemd/system/slurmd.service
[Unit]
Description=Slurm node daemon
After=munge.service network-online.target remote-fs.target slurmctld.service
Wants=network-online.target
#ConditionPathExists=/etc/slurm/slurm.conf

[Service]
Type=simple
EnvironmentFile=-/etc/sysconfig/slurmd
EnvironmentFile=-/etc/default/slurmd
ExecStart=/usr/sbin/slurmd --conf-server admin:6817 -D -s $SLURMD_OPTIONS
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
LimitNOFILE=131072
LimitMEMLOCK=infinity
LimitSTACK=infinity
Delegate=yes
TasksMax=infinity

# Uncomment the following lines to disable logging through journald.
# NOTE: It may be preferable to set these through an override file instead.
#StandardOutput=null
#StandardError=null

[Install]
WantedBy=multi-user.target


## 修改
sudo vim /etc/systemd/system/slurmdbd.service
[Unit]
Description=Slurm DBD accounting daemon
After=network-online.target munge.service mysql.service mysqld.service mariadb.service
Wants=network-online.target
ConditionPathExists=/etc/slurm/slurmdbd.conf

[Service]
Type=simple
EnvironmentFile=-/etc/sysconfig/slurmdbd
EnvironmentFile=-/etc/default/slurmdbd
ExecStart=/usr/sbin/slurmdbd -D -s $SLURMDBD_OPTIONS
ExecReload=/bin/kill -HUP $MAINPID
LimitNOFILE=65536
TasksMax=infinity

# Uncomment the following lines to disable logging through journald.
# NOTE: It may be preferable to set these through an override file instead.
#StandardOutput=null
#StandardError=null

[Install]
WantedBy=multi-user.target

#　重启各种服务
sudo systemctl daemon-reload
sudo systemctl restart slurmdbd.service slurmctld.service slurmd.service 
sudo systemctl status slurmdbd.service slurmctld.service slurmd.service 


# 缺少的东西
sudo yum install munge munge-libs munge-devel -y
sudo /usr/sbin/create-munge-key -r -f
sudo sh -c  "dd if=/dev/urandom bs=1 count=1024 > /etc/munge/munge.key"
sudo chown munge: /etc/munge/munge.key
sudo chmod 400 /etc/munge/munge.key
sudo systemctl enable munge
sudo systemctl start munge

touch /var/spool/slurm/slurmctld/trigger_state


echo 0 > /proc/sys/kernel/numa_balancing
sudo echo 0 > /proc/sys/kernel/numa_balancing

sudo tee /usr/local/bin/sys-optimize.sh > /dev/null << 'EOF'
#!/bin/bash
swapoff -a
echo 0 > /proc/sys/kernel/numa_balancing
echo 0 > /proc/sys/kernel/randomize_va_space
echo 'never' > /sys/kernel/mm/transparent_hugepage/defrag
/usr/bin/cpupower frequency-set -g performance
/usr/bin/cpupower -c 0-95 idle-set -d cc6
/usr/bin/cpupower -c 0-95 idle-set -d 2
EOF

sudo chmod +x /usr/local/bin/sys-optimize.sh
sudo tee /etc/systemd/system/sys-optimize.service > /dev/null << 'EOF'
[Unit]
Description=System Optimization at Boot
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/sys-optimize.sh

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable sys-optimize.service
sudo systemctl start sys-optimize.service 
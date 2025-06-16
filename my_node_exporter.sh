#!binbash



METRICS_FILE="/var/www/html/metrics.txt"



CPU_USAGE=$(top -bn1  grep Cpu(s)  awk '{print 100 - $8}')

MEM_TOTAL=$(free -m  awk 'Mem {print $2}')

MEM_USED=$(free -m  awk 'Mem {print $3}')

DISK_TOTAL=$(df -h   awk 'NR==2 {print $2}')

DISK_USED=$(df -h   awk 'NR==2 {print $3}')



cat EOF  $METRICS_FILE

# HELP cpu_usage CPU usage in percent

# TYPE cpu_usage gauge

cpu_usage $CPU_USAGE



# HELP memory_used Memory used in MB

# TYPE memory_used gauge

memory_used $MEM_USED



# HELP memory_total Total memory in MB

# TYPE memory_total gauge

memory_total $MEM_TOTAL



# HELP disk_used Disk used (in GB)

# TYPE disk_used gauge

disk_used ${DISK_USED-1}



# HELP disk_total Total disk (in GB)

# TYPE disk_total gauge

disk_total ${DISK_TOTAL-1}

EOF


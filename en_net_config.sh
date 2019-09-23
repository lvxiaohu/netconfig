#!/usr/bin/env bash

#Get a list of real network cards
NetworkDevice=`nmcli device show|egrep "GENERAL.DEVICE|GENERAL.设备"|awk '{print $2}'|grep "^e"|head -5|awk '$0=""NR". "$0'`

function network_chose {
    echo -e "Start configuring the network..."
    printf "%-5s|%-10s\n" NICID NICname
    echo -e "===============================\033[32m
${NetworkDevice} \033[0m
==============================="

    read -p  "Choose you need to configure the network card (enter network card ID example: 1):"  NetworkNum
    if [ ! -n "$NetworkNum" ]; then
            echo -e "\033[32m  Is not a valid NIC ID, Please re-enter... \033[0m"
            network_chose
        elif [ $NetworkNum -gt 0 ] ; then
            chose_net_device=`echo "${NetworkDevice}"|sed -n "${NetworkNum}p"|awk '{print $2}'`
            echo -e "The selected NIC file is：\033[32m ${chose_net_device} \033[0m"
        else
        exit 1
    fi
}

function check_ip {
    VALID_CHECK=$(echo $IP|awk -F. '$1<=255&&$2<=255&&$3<=255&&$4<=255{print "yes"}')
    if echo $IP|grep -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$">/dev/null; then
        if [ ${VALID_CHECK:-no} == "yes" ]; then
            continue
        else
            echo -e "\033[31m IP $IP input error, please re-enter \033[0m"
            static_network_set
        fi
    else
        echo "IP format error!"
        exit 1
    fi
}

function static_network_set {
    read -p "Please enter your IPV4 address: "          ipaddr
    read -p "Please enter your NETMASK [Example: 255.255.255.0]: "  ip_netmask
    read -p "Please enter your gateway address: "  ip_gw
    read -p "Please enter your DNS address: "  ip_dns
    for IP in $ipaddr $ip_netmask $ip_gw $ip_dns;do
        check_ip
        done
    echo "" > /etc/sysconfig/network-scripts/ifcfg-$chose_net_device
cat << EOF > /etc/sysconfig/network-scripts/ifcfg-$chose_net_device
TYPE=Ethernet
NAME=$chose_net_device
IPADDR=$ipaddr
NETMASK=$ip_netmask
GATEWAY=$ip_gw
DNS1=$ip_dns
DEVICE=$chose_net_device
ONBOOT=yes
USERCTL=no
BOOTPROTO=static
#PEERDNS=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
IPV6_PRIVACY=no
EOF
}

function dhcp_network_set {
cat << EOF > /etc/sysconfig/network-scripts/ifcfg-$chose_net_device
TYPE=Ethernet
NAME=$chose_net_device
DEVICE=$chose_net_device
ONBOOT=yes
USERCTL=no
BOOTPROTO=dhcp
#PEERDNS=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
IPV6_PRIVACY=no
EOF
}

function restart_network () {
    read -p "The network configuration is complete, restart the network (y/n):" yn
    if [ "$yn" == "Y" ] || [ "$yn" == "y" ]; then
            echo "will restart the network..."
            systemctl restart network
        if [ $? -eq 0 ]
        then
            echo "Start Successful"
            else
            echo "Start failed"
        fi
    elif [ "$yn" == "N" ] || [ "$yn" == "n"  ]; then
            echo -e "\033[33m Need to restart the network service after modifying the IP address to enable it, please restart the service manually...[systemctl restart network] \033[0m "
    fi
}

function set_ntp {
    read -p "Network configuration is complete, Start syncing time? (NTP SYNC) (y/n):" yn
    if [ "$yn" == "Y" ] || [ "$yn" == "y" ]; then
    read -p "Please enter your NTP address："  ip_ntp
    which ntpdate > /dev/null
        if [ $? -eq 0 ];then
            echo ""
        else
            echo "The NTP client is not installed, it will be installed with Yum"
            yum install ntpdate -y
            if [ $? -eq 0 ];then
            echo ""
            else
                echo "NTP installation failed, please download and install manually"
            fi
        fi
    echo -e "\033[34m time synchronization......... \033[0m"
    ntpdate -u $ip_ntp > /dev/null
        if [ $? -eq 0 ] ;then
            echo -e "\033[32m time synchronization success! \033[0m"
            hwclock -w > /dev/null
            now_date=`date`
            echo -e "The time is now:( ${now_date} )"

        else
            echo -e "\033[31m error: time synchronization failed, please check NTP server correctly correct \033[0m"
        fi
    fi
}

function auto_set {
    read -p "Coming network configuration, whether to continue (y/n):" yn
    if [ "$yn" == "Y" ] || [ "$yn" == "y" ]; then
        network_chose
        read -p "Please select the IP configuration mode（Default static)
Static manual configuration,Please enter:  1
DHCP Please enter:  2
Please select (1/2):" chose_ip
        if [ "$chose_ip" == "2" ] ; then
            dhcp_network_set
            else
            static_network_set
        fi
        restart_network
    else
        set_ntp
        exit 1
    fi
}

function main {
    auto_set
    set_ntp
}

main

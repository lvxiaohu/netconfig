#!/usr/bin/env bash
#! /bin/bash

#获取真实网卡列表
NetworkDevice=`nmcli device show|grep GENERAL.DEVICE:|awk '{print $2}'|grep "^e"|head -5|awk '$0=""NR". "$0'`

#echo  -e """网卡信息:\n \033[32m ${NetworkDevice}\033[0m"""
function network_chose {
    echo -e "开始配置网络..."
    printf "%-5s|%-10s\n" 网卡ID 网卡名称
    echo -e "===============================\033[32m
${NetworkDevice} \033[0m
==============================="

    read -p  "选择你需要配置网卡(输入网卡ID 例：1 ):"  NetworkNum
    if echo $NetworkNum | grep -q '[^0-9]'
        then
            echo -e "\033[32m 不是有效的网卡ID，请重新输入... \033[0m"
            network_chose
        else
            chose_net_device=`echo "${NetworkDevice}"|sed -n "${NetworkNum}p"|awk '{print $2}'`
    fi
    echo -e "配置的网卡文件为：\033[32m ${chose_net_device} \033[0m"
}

function check_ip {
    VALID_CHECK=$(echo $IP|awk -F. '$1<=255&&$2<=255&&$3<=255&&$4<=255{print "yes"}')
    if echo $IP|grep -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$">/dev/null; then
        if [ ${VALID_CHECK:-no} == "yes" ]; then
            continue
        else
            echo -e "\033[31m IP $IP 输入错误，请重新输入 \033[0m"
            static_network_set
        fi
    else
        echo "IP format error!"
        exit 1
    fi
}

function static_network_set {
    read -p "请输入请你的IPV4地址："          ipaddr
    read -p "请输入请你的子网掩码/NETMASK[例:255.255.255.0]："  ip_netmask
    read -p "请输入请你的网关地址："  ip_gw
    read -p "请输入请你的DNS地址："  ip_dns
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
    read -p "网络配置已完成，是否重启网络(y/n):" yn
    if [ "$yn" == "Y" ] || [ "$yn" == "y" ]; then
            echo "将要重启网络..."
            systemctl restart network
        if [ $? -eq 0 ]
        then
            echo "启动成功"
            else
            echo "启动失败"
        fi
    elif [ "$yn" == "N" ] || [ "$yn" == "n"  ]; then
            echo -e "\033[34m 修改IP地址后需要重启网络服务使之生效，请手动重启服务...[systemctl restart network] \033[0m "
    fi
}

function set_ntp {
    read -p "网络配置已完成，是否同步NTP（时间服务器）(y/n):" yn
    if [ "$yn" == "Y" ] || [ "$yn" == "y" ]; then
    read -p "请输入请你的NTP地址："  ip_ntp
    which ntpdate > /dev/null
        if [ $? -eq 0 ];then
            echo ""
        else
            echo "没有安装NTP客户端，即将使用Yum安装"
            yum install ntpdate -y
        if [ $? -eq 0 ];then
        echo ""
        else
            echo "NTP安装失败，请手动下载安装"
        fi
        fi
    echo -e "\033[34m 时间同步中...... \033[0m"
    ntpdate -u $ip_ntp > /dev/null
    hwclock -w > /dev/null
        if [ $? -eq 0 ]
        then
            echo -e "\033[32m 时间同步成功! \033[0m"
            now_date=`date`
            echo -e "现在的时间为:( ${now_date} )"
        else
            echo -e "\033[31m 错误:时间同步失败,请检查NTP服务器是否正确 \033[0m"
        fi
    fi
}

function auto_set {
    read -p "即将进行网络配置，是否继续(y/n):" yn
    if [ "$yn" == "Y" ] || [ "$yn" == "y" ]; then
        network_chose
        read -p "请选择IP配置方式,静态[Static]手动配置请输入:1 [DHCP]请输入:2  请选择(1/2):" chose_ip
        if [ "$chose_ip" == "2" ] ; then
            dhcp_network_set
            else
            static_network_set
        fi
        restart_network
    else
        exit 1
    fi
}

function main {
    auto_set
    set_ntp
}

main

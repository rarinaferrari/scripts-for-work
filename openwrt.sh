#!/bin/bash


if [[ $UID -ne 0 ]]; then
   echo "Этот скрипт должен быть запущен от имени root" 
   exit 1
fi


ip="192.168.1.1" # IP address OpenWrt
ssid="OpenWRT"
password="your_pass"
encryption="psk2" 
dhcp_server="x.x.x.x"

echo ">>> Производим настройку хостовой сети"


#Сделать проверку на то, что указанный интерфейс определился корректно, иначе он настроит левый
link_host() {
    iface=$(ip a | awk '/^[[:digit:]]+:/ {gsub(/:/,"",$2); iface=$2} /^    link\/ether/ {print iface}' | tail -n 1)
    echo $iface

    ip link set dev $iface up
    ip addr add 192.168.1.10/255.255.255.0 dev $iface
 

}
grep -qc "192.168.1.10" <<< "$(ip a)" || link_host

echo ">>> Настройка роутера"
# Получим мак адрес роутера
if ping -c 1 -W 1 $ip > /dev/null; then
    mac=$(arping -c 1 -I "$iface" "$ip" | awk '/Unicast reply/ {print $5}' | sed 's/\[//g;s/\]//g')
    echo $mac
else
    echo "роутер не доступен $ip"
    exit
fi
# Тут мы настраиваем роутер

ssh-keygen -R $ip && ssh -o StrictHostKeyChecking=no root@$ip <<EOF

# Меняем статику на dhcp-клиент
    uci set network.lan.proto=dhcp
    uci commit network
# Открываем порты для lan
    nft add table inet filter
    nft add chain inet filter input { type filter hook input priority 0\; }
    nft add rule inet filter input iifname "lan" tcp dport {22, 80, 443} accept
# Настройка беспроводной сети
    uci set wireless.radio0.htmode='HT40'
    uci set wireless.radio0.channel='auto'
    uci set wireless.radio0.hwmode='11a'
    uci set wireless.radio0.country='RU'
    uci set wireless.radio0.disabled='0'

    uci set wireless.default_radio0.disabled='0'
    uci set wireless.default_radio0.mode='ap'
    uci set wireless.default_radio0.ssid='$ssid'
    uci set wireless.default_radio0.encryption='$encryption'
    uci set wireless.default_radio0.key='$password'

    uci set wireless.default_radio0.ieee80211r='1'
    uci set wireless.default_radio0.ft_over_ds='1'
    uci set wireless.default_radio0.ft_psk_generate_local='1'
    uci set wireless.default_radio0.network='lan'
    uci commit wireless

    reboot -n
EOF

echo ">>> Переключите роутер в сеть"
while true; do
    read -p "Роутер подключен к сети y/n ? " yn
    case $yn in
        [Yy]* ) echo "Ожидаем пока роутер получит новый IP-адрес"; sleep 40; break;;
        [Nn]* ) echo "Новый IP получить не удалось"; exit;;
        * ) echo "Please answer yes or no.";;
    esac
done


get_ip_by_mac() {
    # Игнорируем регистр в MAC-адресе
    mac=$(echo "${mac,,}")
    echo $mac
    # Получаем список IP-адресов, выданных DHCP-сервером
    LEASES=$(ssh -o StrictHostKeyChecking=no root@$dhcp_server "cat /var/lib/dhcp/dhcpd.leases")
    # Ищем запись с нужным MAC-адресом
    IP=$(echo "$LEASES" | grep -B 8 "hardware ethernet ${mac};" | tail -n 9 | awk '/lease/{print $2; exit}')
    # Возвращаем IP-адрес (или пустую строку, если не найден)
    echo "$IP"
}

get_ip_by_mac

if [ -z "$IP" ]; then
    echo "IP-адрес для MAC-адреса $mac не найден"
else
    echo "IP-адрес для MAC-адреса $mac: $IP"
fi

# После подключения в сеть и получения нового ip можем уже настроить GUI


if ping -c 1 -W 1 $IP > /dev/null; then
    ssh-keygen -R $IP && ssh -o StrictHostKeyChecking=no root@$IP <<EOF
    opkg update && opkg install luci
    opkg install luci-i18n-base-ru
    wifi
EOF
else 
    echo "роутер не доступен $IP"
    exit
fi

echo "Роутер настроен, добро пожаловать: http://$IP "

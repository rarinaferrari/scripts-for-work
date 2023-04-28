#!/bin/bash

IP_ADDRESS="x.x.x.x" # Шлюз основного канала(Телрос)
MAX_FAILS=5 # Максимальное количество неудачных попыток подряд, чтобы сработало действие

# Периодичность проверки доступности IP-адреса
PING_INTERVAL=60 # В секундах

# Количество минут до выполнения первого действия при недоступности мониторингового IP-адреса
FAIL_LIMIT=5

# Количество минут до выполнения второго действия при успешном мониторинге в течение 30 минут
SUCCESS_LIMIT=30

# Счетчики неудачных и успешных попыток
fails_count=0
success_count=0


# Шаблоны писем
reserve_msg="Основной канал Верево $IP_ADDRESS был недоступен в течение 5 минут, выполнено переключение на резервный"
main_msg="Основной канал Верево $IP_ADDRESS стабильно доступен, переключились на него"

# Логи
LOG_FILE="/var/log/ip_monitoring.log"
date="$(date '+%Y-%m-%d %H:%M:%S')"

[[ -e /var/log/ip_monitoring.log ]] || touch "$LOG_FILE" && chmod 644 "$LOG_FILE"

echo "$date script started" >> $LOG_FILE


# Функция переключения на резервный канал
reserve_link() {
    echo "$date Выполняем переключение канала на резервный" >> $LOG_FILE
    cp -a /etc/shorewall.reserve/* /etc/shorewall/
    ssh domain.dmz <<EOF
    echo "$reserve_msg" | sendmail -t admin@calculate.ru
EOF
}

# Функция возврата на основной канал
main_link() {
    echo "$date Возвращаемся на основной канал" >> $LOG_FILE
    cp -a /etc/shorewall.main/* /etc/shorewall/
    ssh domain.dmz <<EOF 
    echo "$main_msg" | sendmail -t admin@calculate.ru
EOF
}



# Функция для проверки доступности IP-адреса
check_ip_address() {
    if ping -c1 -w1 "$IP_ADDRESS" >/dev/null; then
        # IP-адрес доступен
        if (( fails_count >= 1 )); then 
            fails_count=0
            success_count=0
        elif (( success_count < SUCCESS_LIMIT )); then 
            (( success_count++ ))
            if (( success_count == SUCCESS_LIMIT )); then
                # Доступен 30 минут, возвращаем основной канал
                main_link
            fi
        fi
    else
         echo "$date IP-адрес $IP_ADDRESS недоступен ($fails_count неудачных попыток подряд)" >> $LOG_FILE
        (( fails_count++ ))
        if (( fails_count == MAX_FAILS )); then
            # 5 минут, переключаем канал
            reserve_link
            fails_count=0
            success_count=0
        
        fi
    fi
}

while true; do
    check_ip_address
    sleep "$PING_INTERVAL"
done

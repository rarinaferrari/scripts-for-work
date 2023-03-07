#! /bin/bash 

set -euo pipefail
#trap 'echo "# $BASH_COMMAND";read' DEBUG

echo "Не забудьте подключить телефон, чтобы скрипт считал Serial number!"

WORKPOST={:-}
SIPTEL={:-}

read -p "Введите логин: " LOGIN
read -p "Введите последние 4 цифры моб номера: " mobile
read -p "Введите должность: "   WORKPOST

MOBILE="+7921444$mobile"

if [[ -z $LOGIN ]] || [[ -z $mobile ]] || [[ -z $WORKPOST ]]; then

        echo "./createuser.sh \$LOGIN '4 цифры моб номера' должность из ВИКИ"
        exit 1

elif [[ -e accounts/$LOGIN ]]; then
        echo "Аккаунт уже существует"
        exit 1
fi

case $WORKPOST in
        "Генеральный директор"|"Технический директор") GROUP="all";;
        "Офис-менеджер") GROUP="officemanager";;
        "Менеджер по персоналу"|"Менеджер по кадровому учету"|"Менеджер по подбору персонала") GROUP="job";;
        "Юрисконсульт") GROUP="lawyer";;
        "Руководитель отдела продаж") GROUP="topmanager";;
        "Cтарший менеджер"|"Фронт менеджер"|"Аккаунт менеджер"|"Сервис менеджер"|"Менеджер по продажам") GROUP="manager";;
        "Руководитель РТО"|"Технолог"|"Главный технолог") GROUP="calculation";;
        "Руководитель отдела закупок"|"Менеджер по закупкам") GROUP="supply";;
        "Курьер") GROUP="courier";;
        "Руководитель отдела дизайна"|"Дизайнер") GROUP="draw";;
        "Руководитель конструкторского отдела"|"Конструктор"|"Ассистент конструктора") GROUP="draw";;
        "Главный бухгалтер"|"Заместитель главного бухгалтера"|"Бухгалтер") GROUP="";;
        "Руководитель IT-отдела"|"Программист"|"Системный администратор") GROUP="it";;
        "Руководитель филиала Москва") GROUP="topmanager";;
        "Ведущий менеджер по продажам") GROUP="mskmanager";;
        "Директор производства") GROUP="topmechanic";;
        "Начальник производства") GROUP="works";;
        "Главный механик"|"Старший механик") GROUP="mechanic";;
        "Специалист по планированию") GROUP="work";;
        "Начальник отдела контроля качества"|"Контролер отдела контроля качества"|"Кладовщик") GROUP="storage";;
        "Мастер"*|"Специалист по охране труда"|"Оператор ввода в 1С"|"Водитель погрузчика") GROUP="master";;
        "Заведующий складом") GROUP="topstorage";;
        "Логист") GROUP="logist";;
        "Водитель"*) GROUP="busdriver";;
        *) GROUP="";;
esac


SIPTEL=$(ssh x.x.x.x psql -U postgres userstatus <<EOF | sed -n '3p' | cut -c2-
	select tel from users where username='$LOGIN';
EOF
)


if [[ $SIPTEL =~ ^[12]..$ ]]; then	
	SIPPASS=$(ssh x.x.x.x rasterisk -rx \"pjsip show auth \"${SIPTEL}\"1\" | grep password | cut -d" " -f10)
elif [[ $SIPTEL =~ ^[35]..$ ]]; then
	SIPPASS=$(ssh x.x.x.x rasterisk -rx \"pjsip show auth \"${SIPTEL}\"1\" | grep password | cut -d" " -f10)
elif [[ $SIPTEL =~ ^4..$ ]]; then
	SIPPASS=$(ssh x.x.x.x rasterisk -rx \"pjsip show auth \"${SIPTEL}\"1\" | grep password | cut -d" " -f10)
else
	echo $SIPTEL, проверьте корректность номера
	exit 1
fi

get_creds() {
	declare -a array
	array=( $(ssh x.x.x.x "grep $LOGIN /var/calculate/bin/out.txt"))
	array+=( $(ssh x.x.x.x "grep $LOGIN /var/calculate/bin/nccreds.txt"))
	array+=( $(ssh x.x.x.x "grep $LOGIN /var/calculate/bin/rccreds.txt"))
	array+=( $(ssh x.x.x.x "grep $LOGIN /var/calculate/bin/out.txt"))

	MAIL=${array[1]}
	MAILPASS=${array[3]}
	NCPASS=${array[6]}
	RCPASS=${array[9]}
	TAIGAPASS=${array[11]}
}
get_creds


export_serial () {
	adb kill-server &> /dev/null
	adb start-server &> /dev/null
	adb get-serialno
}

export_fullname () {
	ssh x.x.x.x "psql -U postgres userstatus" <<EOF | sed -n '3p' | cut -c2- 
	select fio from users where username='$LOGIN';
EOF
}


cat > accounts/$LOGIN <<-EOF 
	export SERIAL="$(export_serial)"
	export FULLNAME="$(export_fullname)"
	export LOGIN="$LOGIN"
	export SIPTEL="$SIPTEL"
	export SIPPASS="$SIPPASS"
	export MOBILE="$MOBILE"
	export EMAIL="$MAIL@calculate.ru"
	export EMAIL_PASSWORD="$MAILPASS"
	export WORKPOST="$WORKPOST"
	export NCPASSWORD="$NCPASS"
	export ROCKETCHAT_PASSWORD="$RCPASS"
	export TAIGA_PASSWORD="$TAIGAPASS"
	export XMPP_PASSWORD="-"

	source groups/$GROUP
EOF

echo "файл env готов, вы можете добавить дополнительные пакеты для установки непосредственно в сам .env"

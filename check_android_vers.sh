#! /bin/bash 

rm /tmp/vendors

SAMSUNG=0
XIAOMI=0


for i in $(ls accounts/ | grep -v disabled | grep -v group | grep -v test ); do
  if ping -c 1 $i.mobile &> /dev/null; then
     timeout 2 adb connect $i.mobile:2002 &>/dev/null
     if [[ $? == 0 ]]; then
     version=$(adb shell getprop ro.build.version.release)
     fi

          if [[ $? == 0 ]]; then
                if [[ $version -ge 11 ]]; then
                        ((SAMSUNG++))
                        echo samsung= $SAMSUNG
                        echo $i SAMSUNG >> /tmp/vendors
                else
                        ((XIAOMI++))
                        echo xiaomi= $XIAOMI
                        echo $i  XIAOMI >> /tmp/vendors
                fi
                else
                        echo adb keys not found in $i >> /tmp/vendors
          fi
     adb disconnect $i.mobile:2002 &> /dev/null
  else
     echo destination host unreachable $i >> /tmp/vendors
  fi
done

echo samsung= $SAMSUNG
echo xiaomi= $XIAOMI

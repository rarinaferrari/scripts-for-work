#!/bin/bash
set -e 
for table in $(cat /tmp/2);
do psql -U postgres acoolaru <<EOF > /tmp/count
select count(*) from $table;
EOF
n=$(sed -n '3p' /tmp/count)
l=0
while [ $l -lt $n ];
do echo $table $l
psql -U postgres -d acoolaru -c "select * from $table limit 1 offset $l" >/dev/null || echo $l
l=$(($l+1))
done
done

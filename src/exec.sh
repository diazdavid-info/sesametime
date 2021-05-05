#!/bin/sh

DOMAIN=https://back.sesametime.com
#DOMAIN=https://enui21fykvhulxu.m.pipedream.net

#Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

trap ctrl_c INT

ctrl_c() {
  print_info "Saliendo"
  exit 0
}

print_info() {
  printf "${yellowColour}[*]${endColour}${grayColour}%s${endColour}\n" "$1"
}

print_error() {
  printf "${yellowColour}[*]${endColour}${redColour}%s${endColour}\n" "$1"
}

check_credential() {
  response=$(curl --write-out '%{http_code}' -s -o /dev/null $DOMAIN'/api/v3/security/login' \
    -H 'content-type: application/' \
    -d '{"platformData":{"platformName":"Chrome","platformSystem":"Mac/iOS","platformVersion":"89"},"email":"'"$USER_NAME"'","password":"'"$USER_PASS"'"}')

    if [ "$response" != 200 ]; then
      print_error "Las credenciales no son validas"
      exit 1
    fi
}

log_in() {
  curl -s -o /dev/null $DOMAIN'/api/v3/security/login' \
    -H 'content-type: application/' \
    -d '{"platformData":{"platformName":"Chrome","platformSystem":"Mac/iOS","platformVersion":"89"},"email":"'"$USER_NAME"'","password":"'"$USER_PASS"'"}' \
    -c cookies.txt
}

work_status() {
  STATUS=$(curl -s $DOMAIN'/api/v3/security/me' \
    -b cookies.txt |
    jq '.data[0].workStatus' | sed "s/\"//g")

  echo "$STATUS"
}

check_absence() {
  id=$(user_id)
  current_date=$(date +"%Y-%m-%d")
  curl -s -o /dev/null $DOMAIN'/api/v3/day-off-permission-requests' \
    -H 'content-type: application/json;charset=UTF-8' \
    -d '{"daysOff":[{"date":"'"$current_date"'"}],"absenceTypeId":"9d59a89b-748a-4362-9bbe-7cbf2cec4061","startTime":null,"endTime":null,"hours":null,"allowHour":false,"allowSingleHour":false,"comment":"","documents":[],"directoryId":"bb53b9f4-567b-4391-897d-1c0fcc483faa","entity":"employee","entityId":"'"$id"'","dayOffRequestType":"create"}' \
    -b cookies.txt
}

user_id() {
  USER_ID=$(curl -s $DOMAIN'/api/v3/security/me' \
    -b cookies.txt |
    jq .'data[0].id' | sed "s/\"//g")

  echo "$USER_ID"
}

pause() {
  id=$(user_id)
  curl -s -o /dev/null $DOMAIN'/api/v3/employees/'"$id"'/pause' \
    -H 'content-type: application/json;charset=UTF-8' \
    -d '{"origin":"web","coordinates":{"latitude":null,"longitude":null},"workBreakId":"5fd6f242-85cb-46cf-9ffc-5e89f590aefa"}' \
    -b cookies.txt
}

check_in() {
  status=$(work_status)
  if [ "$status" = "remote" ]; then
    print_info "Estado trabajando...."
    return
  fi

  id=$(user_id)
  curl -s -o /dev/null $DOMAIN'/api/v3/employees/'"$id"'/check-in' \
    -H 'content-type: application/json;charset=UTF-8' \
    -d '{"origin":"web","coordinates":{"latitude":null,"longitude":null}}' \
    -b cookies.txt
}

normal_flow() {
  print_info "Es día laboral de lunes a jueves"
  current_hour=$(date +"%H")
  while [ "$current_hour" -ne "09" ]; do
    print_info "Aun no son las 09:00... me duermo"
    sleep 1m
    current_hour=$(date +"%H")
  done

  check_absence
  check_in

  current_hour=$(date +"%H")
  while [ "$current_hour" -ne "14" ]; do
    print_info "Aun no son las 14:00... me duermo"
    sleep 1m
    current_hour=$(date +"%H")
  done

  pause

  current_hour=$(date +"%H")
  while [ "$current_hour" -ne "15" ]; do
    print_info "Aun no son las 15:00... me duermo"
    sleep 1m
    current_hour=$(date +"%H")
  done

  check_in

  current_day=$(date +"%d")
  while [ "$DAY" = "$current_day" ]; do
    print_info "Mismo día... me duermo"
    sleep 1m
    current_day=$(date +"%d")
  done
}

special_flow() {
  print_info "Es día laboral viernes"
  current_hour=$(date +"%H")
  while [ "$current_hour" -ne "08" ]; do
    print_info "Aun no son las 08:00... me duermo"
    sleep 1m
    current_hour=$(date +"%H")
  done

  check_absence
  check_in

  current_day=$(date +"%d")
  while [ "$DAY" = "$current_day" ]; do
    print_info "Mismo día... me duermo"
    sleep 1m
    current_day=$(date +"%d")
  done
}

not_work_flow() {
  print_info "Es fin de semana"
  current_day=$(date +"%d")
  while [ "$DAY" = "$current_day" ]; do
    print_info "Mismo día... me duermo"
    sleep 1m
    current_day=$(date +"%d")
  done
}

sync_date() {
  print_info "Sincronizando la hora del script"
  current_hour=$(date +"%H")
  while [ "$current_hour" -ne "00" ]; do
    print_info "Aun no son las 00:00... me duermo"
    sleep 1m
    current_hour=$(date +"%H")
  done
}

main() {
  check_credential
  sync_date

  while true; do
    DAY=$(date +"%d")
    DAY_OF_WEEK=$(date +"%u")

    log_in

    case $DAY_OF_WEEK in
    1) normal_flow ;;
    2) normal_flow ;;
    3) normal_flow ;;
    4) normal_flow ;;
    5) special_flow ;;
    6) not_work_flow ;;
    7) not_work_flow ;;
    esac
  done
}

main

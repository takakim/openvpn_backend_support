#!/bin/bash

option=0
line_bar()
{
  echo "--------------------------------------"
}

menu()
{
  line_bar
  echo "------------ Setup Script ------------"
  line_bar
  echo " Select the following options:"
  echo " (1) - Install OpenVPN App"
  echo " (2) - Download NordVPN OpenVPN files"
  echo " (3) - Create the credentials"
  echo " (4) - Setup Iptables"
  echo " (5) - Exit"
  line_bar
  printf "Enter option: "
  read option
}

validated_option()
{
  if ! [[ "$option" =~ ^[1-5]+$ ]] 
    then
      line_bar
      echo "Sorry option ($option) is invalid"
  fi
}

while [ ! -n "$option" ] || [ $option != 5 ]; do
  menu
  validated_option
done
echo "Exiting script"

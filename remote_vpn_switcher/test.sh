#!/bin/bash

distro=`grep -oP 'ID_LIKE=\K\w+' /etc/os-release`
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

install_openvpn()
{
  case ${distro^^} in
    DEBIAN)
      apt-get install -y openvpn
      ;;
    ARCH)
      pacman -S openvpn
      ;;
    FEDORA)
      yum install openvpn
      ;;
    *)
      echo "Sorry, distro not supported"
      ;;
  esac
}

download_openvpn()
{
  wget https://downloads.nordcdn.com/configs/archives/servers/ovpn.zip
  unzip ovpn.zip -d /etc/openvpn/servers
  rm ovpn.zip
}

create_authentication()
{
  echo -n Username: 
  read username
  echo
  echo -n Password: 
  read -s password
  echo
  # Run Command
  printf "$username\n$password" > /etc/openvpn/auth.txt
  chmod 600 /etc/openvpn/auth.txt
}

validated_option()
{
  if ! [[ "$option" =~ ^[1-5]+$ ]] 
    then
      line_bar
      echo "Sorry option ($option) is invalid"
  else
    case ${option} in
    1)
      echo "option 1 selected"
      install_openvpn
      ;;
    2)
      echo "option 2 selected"
      download_openvpn
      ;;
    3)
      echo "option 3 selected"
      create_authentication
      ;;
    esac
  fi
}

[ "$UID" -eq 0 ] || exec sudo "$0" "$@"
while [ ! -n "$option" ] || [ $option != 5 ]; do
  menu
  validated_option
done
echo "Exiting script"

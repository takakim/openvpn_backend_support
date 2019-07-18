#!/bin/bash
set -e
#######
## Arguments $1 LAN interface name $2 the vpn interface
#######

interface=$1
vpn_interface=$2
distro=`grep -oP 'ID_LIKE=\K\w+' /etc/os-release`
package=([0]="iptables" [1]="iptables-persistent")
not_supported=false

#######
## Method responsible for installing the packages
#######
install_package()
{
  case ${distro^^} in
    DEBIAN)
      apt-get install ${package[@]}
      ;;
    ARCH)
      pacman -S ${package[@]}
      ;;
    FEDORA)
      yum install ${package[@]}
      ;;
    *)
      echo "Sorry, distro not supported"
      ;;
  esac
}

#######
## Method responsible identify is the packages are installed
#######
is_package_installed()
{
  case ${distro^^} in
    DEBIAN)
      if ! dpkg -l | grep -qw ${package[0]}; then
        false
      else
        true
      fi
      ;;
    ARCH)
      if ! pacman -Qq | grep -qw ${package[0]}; then
        false
      else
        true
      fi
      ;;
    FEDORA)
      if ! rpm -qa | grep -qw ${package[0]}; then
        false
      else
        true
      fi
      ;;
    *)
      echo "Sorry, distro not supported"
      not_supported=true
      false
      ;;
  esac
}

iptables_enable_rules()
{
  sleep 3
  #######
  ## Requesting sudo and enabling NAT over IPv4
  #######
  sudo /bin/su -c "echo -e '\n#Enable IP Routing\nnet.ipv4.ip_forward = 1' > /etc/sysctl.conf"

  nat=`sudo sysctl -p`
  # must have the following result => "net.ipv4.ip_forward = 1"
  nat_expect="net.ipv4.ip_forward = 1"
  if ! [ "$nat" == "$nat_expect" ]; then
    echo "Not able to enable NAT"
    exit 1
  fi
  sudo iptables -t nat -A POSTROUTING -o $vpn_interface -j MASQUERADE
  sudo iptables -A FORWARD -i $interface -o $vpn_interface -j ACCEPT
  sudo iptables -A FORWARD -i $vpn_interface -o $interface -m state --state RELATED,ESTABLISHED -j ACCEPT
  sudo iptables -A INPUT -i lo -j ACCEPT
  sudo iptables -A INPUT -i $interface -p icmp -j ACCEPT

  #Allowing ssh from the LAN
  sudo iptables -A INPUT -i $interface -p tcp --dport 22 -j ACCEPT

  sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

  #DNS forwarding - working
  sudo iptables -t nat -A PREROUTING -p udp --sport 53 -j DNAT --to-destination 103.86.96.100:53
  sudo iptables -t nat -A PREROUTING -p tcp --sport 53 -j DNAT --to-destination 103.86.96.100:53
}

iptables_reset_rules()
{
  #######
  ## Requesting sudo in order to reset and save the changes
  #######
  sudo /bin/su -c "echo -e '\n#Enable IP Routing\nnet.ipv4.ip_forward = 0' > /etc/sysctl.conf"

  nat=`sudo sysctl -p`
  nat_expect="net.ipv4.ip_forward = 0"
  if ! [ "$nat" == "$nat_expect" ]; then
    echo "Not able to enable NAT"
    exit 1
  fi
  sudo iptables -P FORWARD DROP
  sudo iptables -P INPUT DROP
  sudo iptables -L
}

iptables_save()
{
  case ${distro^^} in
    FEDORA)
      sudo iptables-save > /etc/sysconfig/iptables
      ;;
    ARCH)
      sudo iptables-save > /etc/iptables/iptables.rules
      ;;
    *)
      sudo iptables-save > /etc/iptables/rules.v4
      ;;
  esac
}

#######
## Main function
#######

main()
{
  echo "Verifying package requirements ${package[@]}"
  #######
  ## Making sure the package(s) is installed
  #######

  counter=1
  while [ $counter -le 2 ] && [ $not_supported = false ]
  do
    if ! is_package_installed ; then
      install_package
    fi
    (( counter++ ))
  done

  #######
  ## Exiting when the package(s) is not installed
  #######

  if ! is_package_installed ; then
    echo "Aborting!! Cannot proceed due to ${package[@]} package not being installed"
    exit 1
  else
    if [ "${interface^^}" == "DISABLE" ]; then
      echo "Resetting rules and disabling NAT"
      iptables_reset_rules
      iptables_save
    else
      echo "Continuing with the script adding rules to iptables"
      if [ -z "$interface" ] || [ -z "$vpn_interface" ] 
      then
          echo "Aborting!! Please specify the interfaces LAN and vpn"
          exit 1
      fi

      echo "Adding/enablding rules to iptables"
      iptables_enable_rules

      echo "Saving iptables rules"
      iptables_save
    fi
  fi
  echo 
  echo "That's all folks!"
}

[ "$UID" -eq 0 ] || exec sudo "$0" "$@"
main

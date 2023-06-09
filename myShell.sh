#!/bin/bash

option="${1}"
case ${option} in
   -c)       
	accpu=`top -bn 1 | grep us -w | awk '{ print $8 }'`

	echo "Enter the alert limit(%): "
	read LIMIT

	if [ $(echo "$accpu >= $LIMIT" | bc) -eq 1 ]
	then
		echo "CPU enough!"
	else
		echo -e '\033[43;31mWARNING!\033[0m CPU not enough!'
	fi

	echo "The CPU usage is as follows: "
	top -bn 1 | grep us -w

	echo -e "\033[43;31mThe top 5 processes in using are as follows: \033[0m"
	top -o %CPU -n 1 | awk 'NR==7||NR==8||NR==9||NR==10||NR==11||NR==12'
      ;;
   -r) 
	acram=`free -m| grep Mem -w | awk '{ print $4 }'`

	echo "Enter the alert remnant limit(MB): "
	read LIMIT

	if [ $acram -ge $LIMIT ]
	then
		echo "RAM enough!"
	else
		echo -e '\033[43;31mWARNING!\033[0m RAM not enough!'
	fi

	echo "The RAM usage is as follows: "
	free -h | awk 'NR==1 || NR==2' 

	echo -e "\033[43;31mThe top 5 processes in using are as follows: \033[0m"
	top -o %MEM -n 1 | awk 'NR==7||NR==8||NR==9||NR==10||NR==11||NR==12'
      ;;
   -s) 
	acsp=`df -h | grep / -w | awk '{ print $4 }' | cut -d 'G' -f 1`

	echo "Enter the alert remnant limit(GB): "
	read LIMIT

	if [ $(echo "$acsp >= $LIMIT" | bc) -eq 1 ]
	then
		echo "Space enough!"
	else
		echo -e '\033[43;31mWARNING!\033[0m Space not enough!'
	fi

	echo "The root space usage is as follows: "
	df -h | (awk 'NR==1'); df -h | (grep / -w)
      ;;
   -b) 
	echo "Testing bandwidth, waiting......"
	acbw=$(sudo speedtest-cli --bytes --no-upload | grep Download -w | cut -d ' ' -f 2,3)
	echo "The download bandwidth is: $acbw"
	maxbw=$(echo $acbw | cut -d ' ' -f 1)

	echo "Enter the alert limit(%): "
	read LIMIT

	echo "Testing usage, waiting......"
	sudo iftop -t -s 10 -L 5 > iftmp

	num=$(cat iftmp | grep Cumulative -w | awk '{ print $4 }' | rev | cut -c 3- | rev)
	unit=$(cat iftmp | grep Cumulative -w | awk '{ print $4 }' | rev | cut -c 1,2 | rev)

	unit1=$(echo $unit | cut -c 1)
	unit2=$(echo $unit | cut -c 2)

	case $unit1 in
	    K)  f1=0.001
	    ;;
	    M)  f1=1
	    ;;
	    G)  f1=1000
	    ;;
	esac

	case $unit2 in
	    b)  f2=1
	    ;;
	    B)  f2=8
	    ;;
	esac

	f=$(echo "$f1 * $f2"|bc)
	acbw=$(echo "scale=2; $f / $maxbw"|bc)

	if [ $(echo "$acbw < $LIMIT" | bc) -eq 1 ]
	then
	         echo "bandwidth enough!"
	else
	         echo -e '\033[43;31mWARNING!\033[0m bandwidth not enough!'
	         echo -e "\033[43;31mThe top 5 processes in using are as follows: \033[0m"
	         cat iftmp
	fi

	rm iftmp
      ;;
   *) 
      echo "`basename ${0}`:usage: "
      echo "[-s] see space status"
      echo "[-r] see RAM status"
      echo "[-c] see CPU status"
      echo "[-b] see bandwidth status"
      exit 1 # Command to come out of the program with status 1
      ;;
esac

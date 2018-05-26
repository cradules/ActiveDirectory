#!/bin/bash
#set -x

#########################################################################
#Author: Constatin Radulescu
#Version 2.0
#Description: Kickstart script. Next will be post setup
#	-crontab
#	-join AD server
#	-setup krb5
#	-setup sssd
#	-setup sudo(ers)
#	-instal mailx and setup mail.rc
#	-collect instance information and send to user
#########################################################################




BRANCH=master
NETWORKSYS="/etc/sysconfig/network"
REPOHOME="/root/ActiveDirectory"
SSHCFG="/root/ActiveDirectory/etc/ssh/sshd_config"
SSSDCFG="/root/ActiveDirectory/etc/sssd/sssd.conf"
KRB5CFG="/root/ActiveDirectory/etc/krb5.conf"
SUDODCFGS="/root/ActiveDirectory/etc/sudoers.d"
MAILCFG="/root/ActiveDirectory/etc/mail.rc"
INSTANCESETUP="/tmp/collectinstancedata.txt"
JOINREALM="/root/ActiveDirectory/scripts/join.sh"
KINIT="/root/ActiveDirectory/scripts/kinit.sh"



#Usage
function USAGE () {
        echo "$0 joinadpass"
}


	if [[ $# -ne 1 ]]
		then
		clear
		USAGE
		exit 1
	fi

	if [[ $# -eq 1 ]]
		then 
		PASSWORDAD=$1
	else
		USAGE
		exit 1
	
	fi

	if [[ -d $REPOHOME ]]
		then
		cd $REPOHOME
		git branch -a
		git checkout $BRANCH
	else
		echo "Error. I cant find $REPOHOME"
		exit 1
	fi

#Install packeges 
        yum -y install mailx expect sssd realmd krb5-workstation samba-common-tools adcli

#Install certificates
rsync -aP /root/ActiveDirectory/.certs/ /root/.certs/ 


#Setup HOSTNAME
	if [[ $1 = "-h" ]]
    	then
		sed -i '/HOSTNAME/,1d' $NETWORKSYS; 
		echo "HOSTNAME=$SERVERNAME" >> $NETWORKSYS
		hostname $SERVERNAME
    fi

#Setup root's crontab
#From the moment there is nothing to setup. But this section should be used in case this we change for the future.

#Setup ssh access
	if [[ -f $SSHCFG ]]
		then
		mv /etc/ssh/sshd_config /etc/ssh/sshd_config.orig
		rsync -aP $SSHCFG /etc/ssh/
		/etc/init.d/sshd restart
	fi
#Setup krb5
        mv /etc/krb5.conf /etc/krb5.conf.orig
        rsync -aP $KRB5CFG /etc/



#Join AD 
	
	$JOINREALM $PASSWORDAD
	/usr/sbin/realm leave
#kinit
	$JOINREALM $PASSWORDAD
	$KINIT $PASSWORDAD
	mv /etc/sssd/sssd.conf /etc/sssd/sssd.conf.orig
	rsync -aP $SSSDCFG /etc/sssd/
	chmod 600 /etc/sssd/sssd.conf
	/etc/init.d/sssd restart 

#Setup sudoers
	rsync -aP $SUDODCFGS/ /etc/sudoers.d/



#Rsync sudo rules

rsync -aP /root/ActiveDirectory/etc/sudoers.d/ /etc/sudoers.d/


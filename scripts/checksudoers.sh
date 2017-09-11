#!/bin/bash
set -x

###########################################################################################
#Author: Constantin Radulescu
# 
#Description: Check every minute if there is any sudoers error on deploy branch
#############################################################################################


REPOADDRESS="https://cradulescu@stash.siteworx.com/scm/swxms/puppet-linux-security.git"
REPOHOME="$HOME/puppet-linux-security"
BRANCHSUDO="deploy_sudo"


#Clone puppet-linux-security

	if [[ ! -d $REPOHOME ]]
		then
		cd $HOME
		git clone $REPOADDRESS 
		cd $REPOHOME
		git branch $BRANCHSUDO
		git checkout $BRANCHSUDO
	else
		cd $REPOHOME
		git pull origin $BRANCHSUDO
		git checkout $BRANCHSUDO
	fi
i=0
#Check if sudores has a valid syntax configuration
	for Y in $(find $REPOHOME/etc/sudoers.d/ -type f)
	do
	SUDOERROR="/tmp/sudoerror"
	ERRORNR=$(visudo -cf $Y 2>&1 | grep -v Warning | grep -c error)
		
		if [[ $ERRORNR -ne 0 ]]
			then
			let i++
			visudo -cf $Y 2>&1 | grep -v Warning | grep error | grep -v ">>>" > $SUDOERROR.$i
		fi
		
	 done

#Check errors and send mail to the author an escalate if is the case
ERRORFILENR=$(find /tmp -type f -name "sudoerror.*" |wc -l)
SENDMAIL="/tmp/sendmail.txt"
MAILLIST="/tmp/maillist.txt"

	if [[ $ERRORFILENR -ne 0 ]]
		then
		for y in $( cat $SUDOERROR.* | sed 's:/root/puppet-linux-security/::g' | awk '{print $4}')
		do 
			git log $y | grep Author | head -1 >> $SENDMAIL 
		done
	
		cat $SENDMAIL | awk '{print $3}' | sed 's/<//g' | sed 's/>//g' | uniq >> $MAILLIST
		sed -i '1 i\ -Please recheck your sudoers syntax. You have next error on recently added file. The changes will not be deployed' $SUDOERROR.*
		sed -i 's:/root/puppet-linux-security/::g' $SUDOERROR.*
COUNT=0
		for SENDTO in $(cat $MAILLIST)
		do
			let COUNT++
			cat $SUDOERROR.*  | mailx -A gmail -s "Error(s) have been found in your sudoers syntax" $SENDTO 2>/dev/null
			echo $COUNT >> /tmp/$SENDTO.txt 
			ALERT=$(echo $(cat /tmp/$SENDTO.txt) | sed 's/ /+/g' | bc)
			
			if [[ $ALERT -ge 3 ]]
				then
				sed -i "1 i\\ -ESCALATION. Please check the below errors. The file was edited last time by the user with the e-mail adress $SENDTO\\" $SUDOERROR.* 
				cat $SUDOERROR.*  | mailx -A gmail -s "Error(s) have been found sudoers files in the last 30 minutes(Escalation)"  $SENDTO 2>/dev/null
				rm -f /tmp/$SENDTO.txt
			fi
		done
	fi

#If no errors merge deploy into master and push the changes
	
	if [[ $ERRORFILENR -eq 0 ]]
		then
		BRANCH=$(git branch | grep "*" | awk '{print $2}')
		if [[ "$BRANCH" = "$BRANCHSUDO" ]]
			then
			git checkout master
			git merge $BRANCHSUDO -m "Merging deploy_sudo into master"
			git push
			git checkout $BRANCHSUDO
		fi
	fi

rm -f $SUDOERROR.* $SENDMAIL $MAILLIST 

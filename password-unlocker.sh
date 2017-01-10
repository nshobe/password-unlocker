#!/bin/bash
#
# Password-Unlocker
#
# See README
#
# Built by Nathan Shobe

# Environment
PATH='/bin:/usr/bin'
OS=$(uname)
HOST=$(hostname)
HEADER="Users to be modified"
FOOTER="Use the "u" option to update passwords"
ROOTHOME=$(echo ~root)
REPORT="$ROOTHOME/$HOST-Password-Unlock.log"
OUTUSER="$ROOTHOME/LockedUsers.out"
ADMIN='nshobe'
case "$OS" in
  SunOS)
    PASSOPS=' -s '
    HUMANS=':10:'
    ACCFILTER='LK\|NP\|UN'
  ;;
  Linux)
    PASSOPS=' -S '
    HUMANS=':100:'
    ACCFILTER='L\|NP'
  ;;
esac

# Usage, tell people what to do
usage() {
  cat << EOF
#                     #
## Password Unlocker ##
#                     #

Usage:
    [ -l => List users without functional passwords (sends to stdout) ]
    [ -a => Generate admin email report ]
    [ -u => Update User Passwords ]
    [ -r => Log to report file locally ]
    [ -v => Verbose: Enable CLI stdout logging ]

Warning: This must be run as root!"

EOF
  exit 1
}

getUsers() {
  verbose "Finding human users"
  USERS=$(cat /etc/passwd | grep -v nologin | grep "$HUMANS" | awk -F: '{print $1}')
}

## Check to see which users don't have usable passwords
checkUsers() {
  verbose "Checking for users without usable passwords"
  touch $OUTUSER && chown root $OUTUSER && chmod 600 $OUTUSER
  >$OUTUSER
  for i in $USERS; do
    passwd $PASSOPS $i | grep $ACCFILTER | awk '{print $1}' >>$OUTUSER
  done
}

## List users (handy for email and other reporting)
listUsers() {
  echo "$HEADER"
  while read i; do
    echo "$i"
  done<$OUTUSER
  echo "$FOOTER"
}

## Send the admin(s) a notice that something was changed
mailAdmin() {
  verbose "Mailing admin"
  HEADER="The following accounts are in a locked or otherwise unusable state."
  FOOTER="Depending upon options, these accounts will have new passwords generated and emailed."
  listUsers | mailx -s "Accounts without functioning passwords" nshobe
  report "$ADMIN has been emailed a list of users."
}

## Notify the User that their password has been updated/modified
mailUser() {
  verbose "Mailing users"
  while read i; do
    PASS=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
    # Change following email to $i for production change over.
    mailx -s "Auto-Updated Password(s) on $HOST" nshobe <<EOF
#
### Your Password has been changed
#

Due to either account creation or lack of rotation within 30 days your password has been reset to:
$PASS

This means your new credentials are
Username: $i
Password: $PASS
On Server: $HOST

Please login and update password in a timely manner.


If you feel you've received this message by mistake, please forward your concerns to $ADMIN
EOF
  report "User $i password has been reset to $PASS on $HOST and has been emailed."
  done<$OUTUSER
}

# If report option is switched, generate report file
report() {
  verbose "Report function called"
  touch $REPORT && chown root $REPORT && chmod 600 $REPORT
  if [[ $REPORTING -eq 1 ]] ; then
    printf "$(date +%F_%T) $* \n" >>$REPORT
  fi
}

# Extra noise when you want stout info
verbose() {
  if [[ $VERBOSE -eq 1 ]] ; then
    printf "$(date +%F_%T) $* \n"
  fi 
}

# Run with options
parseopts() {

  while getopts "laurvh" OPTION; do
    case "$OPTION" in
      l) OPTL=1      ;;
      a) OPTA=1      ;;
      u) OPTU=1      ;;
      r) REPORTING=1 ;;
      v) VERBOSE=1   ;;
      h) usage       ;;
      *) usage       ;;
    esac
  done
  if [ $# -eq 0 ]; then
    echo "No Options were provided."
    usage
  fi
}
main() {
  verbose "Verbose mode in enabled."
  report "Run initiated"
  getUsers
  checkUsers

## Run based on options
  if [[ $OPTL -eq 1 ]]; then
    listUsers
  fi
  if [[ $OPTA -eq 1 ]]; then
    mailAdmin
  fi
  if [[ $OPTU -eq 1 ]]; then
    mailUser
  fi
}
parseopts $*
main

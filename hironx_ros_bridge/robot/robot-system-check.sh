#!/bin/bash

function usage {
    echo >&2 "usage: $0 [hostname (default:hiro014)] [username (default:hiro)]"
    echo >&2 "          [-h|--help] print this message"
    echo >&2 "          [-a|--all]  check system and jsk code"
    exit 0
}

# command line parse
OPT=`getopt -o ha -l help,all -- $*`
if [ $? != 0 ]; then
    usage
fi

eval set -- $OPT

# system check : check qnx and pre-installed software
# jsk check (check_all) : check code in start-jsk (openrtm,openhrp3,hrpsys)
CHECK_ALL=false

while [ -n "$1" ] ; do
    case $1 in
        -h|--help) usage ;;
        -a|--all) CHECK_ALL=true; shift 2; break ;;
        --) shift; break;;
        *) echo "Unknown option($1)"; usage;;
    esac
done

## Comment out; not used.
#address=`host hrpsys-base.googlecode.com | awk '/^[[:alnum:].-]+ has address/ { print $4 ; exit }'` # this does not work for  Server certificate verification 

commands="
  . ~/.profile;
  env;
  for file in \`ls /tmp/check/*.sh\`; do
   sh \$file;
  done;
  "

hostname=$1
hostname=${hostname:="hiro014"} 
userid=$2
userid=${userid:="hiro"} 

echo ";; Copying check script to $userid@$hostname, SYSTEM_CODE_CHECK=true, JSK_CODE_CHECK=$CHECK_ALL"
exit
scp -r ./check $userid@$hostname:/tmp
echo ";; Execute check scripts"
ssh $userid@$hostname -t $commands 2>&1 | tee robot-system-check-$hostname.log
scp $userid@$hostname:/tmp/check-*-md5.txt ./check/;
git diff 2>&1 | tee -a robot-system-check-$hostname.log

echo ";; Done check scripts, please check robot-system-check-$hostname.log file"
# invoke `git checkout -- .` to revert all


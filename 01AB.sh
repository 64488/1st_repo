#!/bin/sh

curPath=$(cd `dirname $0`;pwd)
confFile=$curPath/00AB.conf
LOG=$curPath/ABlog
source $curPath/../func/mail.sh
source $curPath/../var/hostName

echo -e "`date '+%F %T'`  ===================="

if [ `ls $confFile 2> /dev/null |wc -l` == 0 ];then
  echo -e "**********\n**********"
  echo "there is no $confFile file."
  echo "$confFile的格式是：Port,user,hostname,sourceDIR"
  echo -e "**********\n**********"
  warning="backup failed, lost files"
  body="$(cd $LOG; cat `ls -tr *AB.log |tail -1`)"
  MailToChq "$body"
  exit 1
fi

oldIFS=$IFS
IFS=$'\n'
for i in `egrep -Ev '^[ \t]{0,}#|^[ \t]{0,}$' $confFile`  # 将注释行和空白行去掉
do
  if [ `echo $i |awk -F[\,\ ] '{print NF}'` != 4 ];then
    echo -e "**********\n**********"
    echo "the following line(s) are in a wrong format, please check file $confFile and correct it:"
    echo "    ${i}"
    echo -e "**********\n**********"
    warning="backup failed, a file is wrong."
    body="$(cd $LOG; cat `ls -tr *AB.log |tail -1`)"
    MailToChq "$body"
    exit 2
  fi
done
IFS=${oldIFS}

BackTo='/mnt/autoBackup'           # 数据备份到哪个目录
mkdir -p $BackTo 2> /dev/null
weekDay="$BackTo/`date +%A`"         # 数据会备份7天
mkdir $weekDay 2> /dev/null
rm -rf $weekDay/*                   # 备份之前把老数据删除

echo -e "Start to backup......\n*****\n*****"
for i in `egrep -Ev '^[ \t]{0,}#|^[ \t]{0,}$' $confFile`  # 将注释行和空白行去掉
do  
  p=`echo "${i}" | awk -F[,] '{print $1}'`
  u=`echo "${i}" | awk -F[,] '{print $2}'`
  h=`echo "${i}" | awk -F[,] '{print $3}'`
  f=`echo "${i}" | awk -F[,] '{print $4}'`
  f2=${f%/*}  								# 删除最右边的'/'和'/后的字符'

  mkdir -p $weekDay/${h}${f2} 2> /dev/null
  scp -rp -P $p "$u"@"$h":"$f" $weekDay/${h}${f2} && echo "successfully backup ${h}:$f" || echo "Fail to backup ${h}:$f"
done

echo -e "*****\n*****\n`date '+%F %T'`  ===================="

if [ $(cd $LOG; grep -c 'Fail' `ls -tr *AB.log |tail -1`) -ne 0 ]; then
  warning="backup with failure to $hostName:${weekDay}"
  echo $warning
  body="$(cd $LOG; cat `ls -tr *AB.log |tail -1`)"
  MailToChq "$body"
else
  warning="backup successfully to $hostName:${weekDay}"
  echo $warning
  body="$(cd $LOG; cat `ls -tr *AB.log |tail -1`)"
  MailToChq "$body"
fi

# 运行脚本前先执行 mkdir -p /root/script/autoBackup/ABlog/
# crontab -e
# MAILTO=""
# 02 03 * * * mkdir -p /root/script/autoBackup/ABlog 2>/dev/null; sh /root/script/autoBackup/01AB.sh >> /root/script/autoBackup/ABlog/`date +\%F`AB.log 2>&1

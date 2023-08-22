#!/usr/bin/env bash

if [[ `uname  -a` =~ "Darwin" ]];then
    echo -e "\033[33m开始检测是否已安装 Emby 客户端...\033[0m"
else
    echo -e "\033[31m非 MacOS 系统，不能使用此脚本解锁 Emby 播放权限\033[0m"
    exit 0
fi

EmbyApp="/Applications/Emby.app"
ConnectionManagerFile="${EmbyApp}/Contents/Resources/www/modules/emby-apiclient/connectionmanager.js"

if [ ! -f "$ConnectionManagerFile" ]; then
    echo -e "\033[31m请先从 https://itunes.apple.com/us/app/emby/id992180193?ls=1&mt=8 安装 Emby 客户端，然后再运行本解锁程序\033[0m"
    exit 0
fi

echo "已安装 Emby 客户端，准备解锁 Emby 播放权限"

reject='var status=(response||{}).status;return console.log("getRegistrationInfo response: "+status),403===status?Promise.reject("overlimit"):status&&status<500?Promise.reject():function(err){if(console.log("getRegistrationInfo failed: "+err),regCacheValid)return console.log("getRegistrationInfo returning cached info"),Promise.resolve();throw err}(response)'

embyVersion=`cat /Applications/Emby.app/Contents/Info.plist | grep -A1 CFBundleShortVersionString | grep string | sed 's/<[^>]*>//g' | sed 's/\t//g'`

if [ "$embyVersion" > '2.1.99' ]; then
     echo -e "当前 Emby 版本大于2.2.0，使用新代码匹配"
     reject='var status=(response||{}).status;if(console.log("getRegistrationInfo response: "+status),status&&status<500&&appStorage.setItem(cacheKey,JSON.stringify({lastValidDate:-1,deviceId:params.deviceId,cacheExpirationDays:0,lastUpdated:Date.now()})),403===status)return Promise.reject("overlimit");if(status&&status<500)return Promise.reject();status=response;if(console.log("getRegistrationInfo failed: "+status),regCacheValid)return console.log("getRegistrationInfo returning cached info"),Promise.resolve();throw status'
fi

resolve='return appStorage.setItem(cacheKey,JSON.stringify({lastValidDate:Date.now(),deviceId:params.deviceId,cacheExpirationDays:999})),Promise.resolve()'

sudo sed -i "" "s/$reject/$resolve/" $ConnectionManagerFile

echo -e "\033[32mEmby 播放权限解锁成功\033[0m"

pid=`ps -ef|grep ${EmbyApp}|grep -v grep|awk '{print $2}'`
if [ ! -z $pid ]; then
    echo -e "\033[32m正在重启 Emby 客户端\033[0m"
    kill -9 $pid
else
    echo -e "\033[32m正在启动 Emby 客户端\033[0m"
fi
open $EmbyApp

exit 0

#!/bin/bash

Geoip2CityDB="GeoLite2-City.mmdb"
WorkPath="/usr/local/nginx"

deps_install(){
   [ ! -x "$(command -v wget)" ] && echo "Error: wget is not installed" >&2 && yum -y install wget
   [ ! -x "$(command -v git)" ] && echo "Error: git is not installed" >&2 && yum -y install git
   [ ! -d "$WorkPath" ] && echo "Error: No such directroy" >&2 && mkdir -p $WorkPath
   cd $WorkPath
   wget https://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz && gunzip GeoLite2-City.tar.gz 
   git https://github.com/SilentGo/nginx.git 
}



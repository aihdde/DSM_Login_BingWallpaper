#user 群晖 NAS 用户名，设置替换桌面壁纸与保存图片文件权限 
user="admin"

#如需设置用户桌面壁纸为每日必应美图，去掉下面 wallpaper 注释 
#DSM 管理页面随意指定一张图片为壁纸，并在创建 wallpaper_dir 目录以及 wallpaper、wallpaper_hd 文件 
wallpaper="/usr/syno/etc/preference/$user/wallpaper_dir/wallpaper"
wallpaper_hd="/usr/syno/etc/preference/$user/wallpaper_dir/wallpaper_hd"

# 设置你的语言
# set your language(en-US,zh-CN...)
lang="zh-CN"

# 如需收集保存壁纸,请去掉下面注释,设置保存文件夹路径
# 在FileStation里面右键文件夹属性可以看到路径
# If you want to collect and save Wallpapers, 
# please remove the comment below and set the savepath.
# Right click the folder property in FileStation to see the path.
savepath="/volume1/media/wallpaper"

# 如需下载4k分辨率,请设置res=4k
# 如需下载体积更大的4k以上分辨率的原始图片,请设置res=raw
# To download 4K resolution, set res=4K
# To download a larger original picture, set res=raw
res=raw

# 修改用户桌面壁纸,注释后会替换系统的wallpaper1
# 你需要清空浏览器缓存查看效果，仅在DSM7.x上测试.
# Modify user desktop wallpaper.Only test for DMS7.x.
# System "Wallpaper1" will replaced by remove the comment.
# You need to clear the browser cache to see the effect.
desktop=yes

echo "[x]Collecting information..."
pic="https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1"
if [ "$res" != "" ]
then pic="https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&uhd=1&uhdwidth=3840&uhdheight=2160"
fi
pic=$(wget -t 5 --no-check-certificate -qO- $pic --header="cookie:_EDGE_S=mkt=$lang")
echo $pic|grep -q startdate||exit
link=$(echo https://www.bing.com$(echo $pic|sed 's/.\+"url"[:" ]\+//g'|sed 's/".\+//g'))

date=$(echo $pic|grep -Eo '"startdate":"[0-9]+'|grep -Eo '[0-9]+'|head -1)
if [ "$date" == "" ]
then date=$(date +%Y%m%d)
fi
title=$(echo $pic|sed 's/.\+"title":"//g'|sed 's/".\+//g')
copyright=$(echo $pic|sed 's/.\+"copyright[:" ]\+//g'|sed 's/".\+//g')
keyword=$(echo $copyright|sed 's/, /-/g'|cut -d" " -f1|grep -Eo '[^()\\/:*?"<>]+'|head -1)
filename="bing_"$date"_"$keyword"_4K.jpg"

#echo "Pic:"$pic
#echo "Link:"$link
echo "Date:"$date
echo "Title:"$title
echo "Copyright:"$copyright
echo "Keyword:"$keyword
echo "Filename:"$filename

echo "[x]Downloading wallpaper..."
tmpfile=/tmp/$filename
wget -t 5 --no-check-certificate  $link -qO $tmpfile
if [ "$res" == "raw" ]
then link_raw=$(echo $link|grep -Eo "https://[-=?/._a-zA-Z0-9]+") 
filename_raw="bing_"$date"_"$keyword"_RAW.jpg"
tmpfile_raw=/tmp/$filename_raw
wget -t 5 --no-check-certificate  $link_raw -qO $tmpfile_raw
fi
ls -lah $tmpfile||exit

echo "[x]Copying wallpaper..."
if [ "$savepath" != "" ]
then cp $tmpfile "$savepath"
	if [ "$res" == "raw" ]
	then cp $tmpfile_raw "$savepath"
	fi
echo "Save:"$savepath
ls -lah "$savepath"|grep $date
cd "$savepath"
chmod 777 $filename
else echo "savepath is not set, skip copy."
fi

echo "[x]Setting welcome msg..."
sed -i s/login_welcome_title=.*//g /etc/synoinfo.conf
echo "login_welcome_title=\"$title\"">>/etc/synoinfo.conf
sed -i s/login_welcome_msg=.*//g /etc/synoinfo.conf
echo "login_welcome_msg=\"$copyright\"">>/etc/synoinfo.conf

echo "[x]Applying login wallpaper..."
sed -i s/login_background_customize=.*//g /etc/synoinfo.conf
echo "login_background_customize=\"yes\"">>/etc/synoinfo.conf
sed -i s/login_background_type=.*//g /etc/synoinfo.conf
echo "login_background_type=\"fromDS\"">>/etc/synoinfo.conf
rm -rf /usr/syno/etc/login_background*.jpg
cp -f $tmpfile /usr/syno/etc/login_background.jpg
ln -sf /usr/syno/etc/login_background.jpg /usr/syno/etc/login_background_hd.jpg

if [ "$desktop" == "yes" ]
then echo "[x]Applying user desktop wallpaper..."
cp -f /usr/syno/etc/login_background.jpg $wallpaper
cp -f /usr/syno/etc/login_background.jpg $wallpaper_hd
fi

echo "[x]Clean..."
rm -f /tmp/bing_*.jpg

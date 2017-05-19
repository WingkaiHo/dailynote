### 1.解压压缩包
tar -zxvf YaHeiConsolas.tar.gz

### 2.在系统目录下创建自定义字体目录
sudo mkdir -p /usr/share/fonts/vista

## 3.复制解压出来的字体到刚才创建的目录
sudo cp YaHeiConsolas.ttf /usr/share/fonts/vista/

## 4.修改字体权限
sudo chmod 644 /usr/share/fonts/vista/*.ttf

## 5.进入字体目录
cd /usr/share/fonts/vista/

##6. 刷新并安装字体
sudo mkfontscale && sudo mkfontdir && sudo fc-cache -fv


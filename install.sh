#!/bin/bash

#bash <(curl -s -L https://raw.githubusercontent.com/CakeSystem/RMS/main/install.sh)
#bash <(curl -s -L -k https://raw.njuu.cf/CakeSystem/RMS/main/install.sh)
#bash <(curl -s -L -k https://raw.yzuu.cf/CakeSystem/RMS/main/install.sh)
#bash <(curl -s -L -k https://raw.nuaa.cf/CakeSystem/RMS/main/install.sh)
clear

[ $(id -u) != "0" ] && { echo "请使用ROOT用户进行安装, 输入sudo -i切换。"; exit 1; }

IS_OPENWRT=false

# Check for OpenWrt
if [ -f /etc/openwrt_version ]; then
    IS_OPENWRT=true
fi


if [ "$IS_OPENWRT" = true ]; then
    echo "This is an OpenWrt system."
else
    if command -v systemctl &> /dev/null; then
        echo "check systemctl..."
        clear
    else
        echo "当前系统不支持systemctl服务, 请先安装systemctl."
        exit 1;
    fi
fi

SERVICE_NAME="CakeMinerervice"

PATH_CakeMiner="/root/CakeMiner"
PATH_EXEC="CakeMiner"
PATH_NOHUP="${PATH_CakeMiner}/nohup.out"
PATH_ERR="${PATH_CakeMiner}/err.log"

ROUTE_1="https://github.com"
ROUTE_2="http://rustminersystem.com"
# ROUTE_2="https://hub.njuu.cf"
# ROUTE_3="https://hub.yzuu.cf"
# ROUTE_4="https://hub.nuaa.cf"

ROUTE_EXEC_1="/CakeSystem/CakeMiner/raw/main/x86_64-musl/CakeMiner"
ROUTE_EXEC_2="/CakeSystem/CakeMiner/raw/main/x86_64-android/CakeMiner"
ROUTE_EXEC_3="/CakeSystem/CakeMiner/raw/main/arm-musleabi/CakeMiner"
ROUTE_EXEC_4="/CakeSystem/CakeMiner/raw/main/arm-musleabihf/CakeMiner"
ROUTE_EXEC_5="/CakeSystem/CakeMiner/raw/main/armv7-musleabi/CakeMiner"
ROUTE_EXEC_6="/CakeSystem/CakeMiner/raw/main/armv7-musleabihf/CakeMiner"
ROUTE_EXEC_7="/CakeSystem/CakeMiner/raw/main/i586-musl/CakeMiner"
ROUTE_EXEC_8="/CakeSystem/CakeMiner/raw/main/i686-android/CakeMiner"
ROUTE_EXEC_9="/CakeSystem/CakeMiner/raw/main/aarch64-musl/CakeMiner"

TARGET_ROUTE=""
TARGET_ROUTE_EXEC=""

UNAME=`uname -m`

filterResult() {
    if [ $1 -eq 0 ]; then
        echo ""
    else
        echo "!!!!!!!!!!!!!!!ERROR!!!!!!!!!!!!!!!!"
        echo "【${2}】失败。"
	
        if [ ! $3 ];then
            echo "!!!!!!!!!!!!!!!ERROR!!!!!!!!!!!!!!!!"
            exit 1
        fi
    fi
    echo -e
}

disable_firewall() {
    os_name=$(grep "^ID=" /etc/os-release | cut -d "=" -f 2 | tr -d '"')
    echo "关闭防火墙"

    if [ "$os_name" == "ubuntu" ]; then
        sudo ufw disable
    elif [ "$os_name" == "centos" ]; then
        sudo systemctl stop firewalld
        sudo systemctl disable firewalld
    else
        echo "未知的操作系统, 关闭防火墙失败"
    fi
}

check_process() {
    if [ "$IS_OPENWRT" = true ]; then
        if pgrep -f "$1" >/dev/null; then
            return 0
        else
            return 1
        fi
    else
        if [[ $(uname) == "Linux" ]]; then
            if pgrep -x "$1" >/dev/null; then
                return 0
            else
                return 1
            fi
        else
            if ps aux | grep -v grep | grep "$1" >/dev/null; then
                return 0
            else
                return 1
            fi
        fi
    fi
}

# openwrt设置开机启动
#!/bin/sh

# Function to set up auto-start and start the program
wrt_enable_autostart() {
    echo "wrt_set_start"
    if [ ! -f /etc/init.d/CakeMiner ]; then
        # Create an init script for the "CakeMiner" service
        echo "#!/bin/sh /etc/rc.common" > /etc/init.d/CakeMiner
        echo "USE_PROCD=1" >> /etc/init.d/CakeMiner
        echo "START=99" >> /etc/init.d/CakeMiner
        echo "start() {" >> /etc/init.d/CakeMiner
        echo "    /root/CakeMiner/CakeMiner &" >> /etc/init.d/CakeMiner
        echo "}" >> /etc/init.d/CakeMiner
        
        echo "PROG=/root/CakeMiner/CakeMiner" >> /etc/init.d/CakeMiner
        echo "start_service(){" >> /etc/init.d/CakeMiner
        echo "  procd_open_instance" >> /etc/init.d/CakeMiner
        echo "  procd_set_param command \$PROG" >> /etc/init.d/CakeMiner
        echo "  procd_set_param respawn" >> /etc/init.d/CakeMiner
        echo "  procd_close_instance" >> /etc/init.d/CakeMiner
        echo "}" >> /etc/init.d/CakeMiner

        chmod +x /etc/init.d/CakeMiner
    fi

    /etc/init.d/CakeMiner enable
    /etc/init.d/CakeMiner start
}

# Function to stop auto-start and stop the program
wrt_disable_autostart() {
    echo "wrt_set_disable"
    if [ -f /etc/init.d/CakeMiner ]; then
        # Stop the "CakeMiner" service
        /etc/init.d/CakeMiner stop

        # Remove the init script
        rm /etc/init.d/CakeMiner
    fi
}


# 设置开机启动且进程守护
enable_autostart() {
    echo "${m_14}"
    if [ "$(command -v systemctl)" ]; then
        sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null <<EOF
[Unit]
Description=My Program
After=network.target

[Service]
Type=simple
ExecStart=$PATH_CakeMiner/$PATH_EXEC
WorkingDirectory=$PATH_CakeMiner/
Restart=always
StandardOutput=file:$PATH_CakeMiner/nohup.out
StandardError=file:$PATH_CakeMiner/err.log
TimeoutStopSec=5

[Install]
WantedBy=multi-user.target
EOF
        sudo systemctl daemon-reload
        sudo systemctl enable $SERVICE_NAME.service
        sudo systemctl start $SERVICE_NAME.service
    else
        sudo sh -c "echo '${PATH_CakeMiner}/${PATH_EXEC} &' >> /etc/rc.local"
        sudo chmod +x /etc/rc.local
    fi
}

# 禁用开机启动函数
disable_autostart() {
    echo "关闭开机启动..."
    if [ "$(command -v systemctl)" ]; then
        sudo systemctl stop $SERVICE_NAME.service
        sudo systemctl disable $SERVICE_NAME.service
        sudo rm /etc/systemd/system/$SERVICE_NAME.service
        sudo systemctl daemon-reload
    else # 系统使用的是SysVinit
        sudo sed -i '/\/root\/rustminersystem\/rustminersystem\ &/d' /etc/rc.local
    fi

    sleep 1
}

kill_process() {
    if [ "$IS_OPENWRT" = true ]; then
        local process_name="$1"
        local pids=($(pgrep -f "$process_name"))
        echo "WRT KILL IPD $pids"
        if kill -9 "$pids" >/dev/null 2>&1; then
            echo "已终止 $pids 进程."
        else
            echo "未发现 $pids 进程."
            return 1
        fi
    else
        local process_name="$1"
        local pids=($(pgrep "$process_name"))
        
        if [ ${#pids[@]} -eq 0 ]; then
            echo "未发现 $process_name 进程."
            return 1
        fi
        for pid in "${pids[@]}"; do
            echo "Stopping process $pid ..."
            kill -TERM "$pid"
        done
        echo "终止 $process_name ."
    fi

    sleep 1
}

change_limit() {
    echo "${m_18}"

    changeLimit="n"

    if [[ -f /etc/debian_version ]]; then
    echo "soft nofile 65535" | sudo tee -a /etc/security/limits.conf
    echo "hard nofile 65535" | sudo tee -a /etc/security/limits.conf
    echo "fs.file-max = 100000" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p

    # add PAM configuration to enable the limits for login sessions
    if [[ -f /etc/pam.d/common-session ]]; then
        grep -q '^session.*pam_limits.so$' /etc/pam.d/common-session || sudo sh -c "echo 'session required pam_limits.so' >> /etc/pam.d/common-session"
        fi
    fi

    # set file descriptor limits for CentOS/RHEL
    if [[ -f /etc/redhat-release ]]; then
        echo "* soft nofile 65535" | sudo tee -a /etc/security/limits.conf
        echo "* hard nofile 65535" | sudo tee -a /etc/security/limits.conf
        echo "fs.file-max = 100000" | sudo tee -a /etc/sysctl.conf
        sudo sysctl -p
    fi

    # set file descriptor limits for macOS
    if [[ "$(uname)" == "Darwin" ]]; then
        sudo launchctl limit maxfiles 65535 65535
        sudo sysctl -w kern.maxfiles=100000
        sudo sysctl -w kern.maxfilesperproc=65535
    fi

    # set systemd file descriptor limits
    if [[ -x /bin/systemctl ]]; then
        echo "DefaultLimitNOFILE=65535" >>/etc/systemd/user.conf
        echo "DefaultLimitNOFILE=65535" >>/etc/systemd/system.conf
        systemctl daemon-reexec
    fi

    if [ $(grep -c "root soft nofile" /etc/security/limits.conf) -eq '0' ]; then
        echo "root soft nofile 65535" >>/etc/security/limits.conf
        echo "* soft nofile 65535" >>/etc/security/limits.conf
        changeLimit="y"
    fi

    if [ $(grep -c "root hard nofile" /etc/security/limits.conf) -eq '0' ]; then
        echo "root hard nofile 65535" >>/etc/security/limits.conf
        echo "* hard nofile 65535" >>/etc/security/limits.conf
        changeLimit="y"
    fi

    if [ $(grep -c "DefaultLimitNOFILE=65535" /etc/systemd/user.conf) -eq '0' ]; then
        echo "DefaultLimitNOFILE=65535" >>/etc/systemd/user.conf
        changeLimit="y"
    fi

    if [ $(grep -c "DefaultLimitNOFILE=65535" /etc/systemd/system.conf) -eq '0' ]; then
        echo "DefaultLimitNOFILE=65535" >>/etc/systemd/system.conf
        changeLimit="y"
    fi

    if [[ "$changeLimit" = "y" ]]; then
        echo "连接数限制已修改为65535,重启服务器后生效"
    else
        echo -n "当前连接数限制："
        ulimit -n
    fi

    echo "修改完成, 重启服务器后生效"
}

install() {
    if [ -f /etc/centos-release ] || \
    ([ -f /etc/lsb-release ] && . /etc/lsb-release && [ "$DISTRIB_ID" = "Ubuntu" ]) || \
    [ -f /etc/openwrt_version ]; then
        echo "CENTOS || UBUNTU || OPENWRT"
    else
        # 在其他操作系统上运行所需的命令
        chown root:root /mnt -R
        chown root:root /etc -R
        chown root:root /usr -R
        chown man:root /var/cache/man -R
        chmod g+s /var/cache/man -R
    fi

    disable_firewall

    check_process $PATH_EXEC

    if [ $? -eq 0 ]; then
        echo "发现正在运行的${PATH_EXEC}需要停止才可继续安装。"
        echo "输入1停止正在运行的${PATH_EXEC}并且继续安装, 输入2取消安装。"

        read -p "$(echo -e "请选择[1-2]：")" choose
        case $choose in
        1)
            stop
            ;;
        2)
            echo "取消安装"
            return
            ;;
        *)
            echo "输入错误, 取消安装。"
            return
            ;;
        esac
    fi

    if [[ ! -d $PATH_CakeMiner ]];then
        mkdir $PATH_CakeMiner
        chmod 777 -R $PATH_CakeMiner
    else
        echo "目录已存在, 无需重复创建, 继续执行安装。"
    fi

    if [[ ! -d $PATH_NOHUP ]];then
        touch $PATH_NOHUP
        touch $PATH_ERR

        chmod 777 -R $PATH_NOHUP
        chmod 777 -R $PATH_ERR
    fi

    echo "开始下载程序..."

    wget -P $PATH_CakeMiner "${TARGET_ROUTE}${TARGET_ROUTE_EXEC}" -O "${PATH_CakeMiner}/${PATH_EXEC}" 1>/dev/null

    filterResult $? "下载程序"

    chmod 777 -R "${PATH_CakeMiner}/${PATH_EXEC}"

    change_limit

    start
}

restart() {
    stop

    start
}

uninstall() {
    stop

    rm -rf ${PATH_CakeMiner}

    if [ "$IS_OPENWRT" = true ]; then
        wrt_disable_autostart
    else
        disable_autostart
    fi

    echo "卸载成功"
}

start() {
    echo $BLUE "启动程序..."
    check_process $PATH_EXEC

    if [ $? -eq 0 ]; then
        echo "程序已经启动，请不要重复启动。"
        return
    else
        # cd $PATH_RUST

        # nohup "${PATH_RUST}/${PATH_EXEC}" 2>$PATH_ERR &

        if [ "$IS_OPENWRT" = true ]; then
            wrt_enable_autostart
        else
            enable_autostart
        fi

        sleep 1

        check_process $PATH_EXEC

        if [ $? -eq 0 ]; then
            echo "|----------------------------------------------------------------|"
            echo "程序启动成功, 访问此地址: 局域网IP:42703"
            echo "|----------------------------------------------------------------|"
        else
            echo "程序启动失败!!!"
        fi
    fi
}

stop() {
    sleep 1

    if [ "$IS_OPENWRT" = true ]; then
        wrt_disable_autostart
    else
        disable_autostart
    fi

    sleep 1

    echo "终止进程..."

    kill_process $PATH_EXEC

    sleep 1
}

echo "------CakeMiner Linux------"
echo "1. 安装"
echo "2. 停止运行CakeMiner"
echo "3. 重启CakeMiner"
echo "4. 卸载CakeMiner"
echo "---------------------"

read -p "$(echo -e "[1-4]：")" comm

if [ "$comm" = "1" ]; then
    clear
elif [ "$comm" = "2" ]; then
    stop
    exit 1
elif [ "$comm" = "3" ]; then
    restart
    exit 1
elif [ "$comm" = "4" ]; then
    uninstall
    exit 1
fi


echo "------CakeMiner Linux------"
echo "当前CPU架构【${UNAME}】"
echo 请选择对应架构安装选项。
echo "---------------------"
echo "1. x86-64"
echo "2. x86-64-android"
echo "3. arm-musleabi"
echo "4. arm-musleabihf"
echo "5. armv7-musleabi"
echo "6. armv7-musleabihf"
echo "7. i586"
echo "8. i686-android"
echo "9. aarch64"
echo ""

read -p "$(echo -e "[1-9]：")" targetExec

VARNAME="ROUTE_EXEC_${targetExec}"
TARGET_ROUTE_EXEC="${!VARNAME}"

clear

echo "------CakeMiner Linux------"
echo "请选择下载线路:"
echo "1. 线路1（github官方地址, 如无法下载请选择其他线路）"
echo "2. 线路2"
# echo "3. 线路3"
# echo "4. 线路4"
echo "---------------------"

read -p "$(echo -e "[1-2]：")" targetRoute

VARNAME="ROUTE_${targetRoute}"
TARGET_ROUTE="${!VARNAME}"

[ ! $TARGET_ROUTE ] && { echo "错误的线路选择命令"; exit 1; }
[ ! $TARGET_ROUTE_EXEC ] && { echo "错误的架构选择命令"; exit 1; }

echo "${TARGET_ROUTE}${TARGET_ROUTE_EXEC}"

install
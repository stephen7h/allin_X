#!/bin/bash

#====================================================
#	System Request:Debian 9+/Ubuntu 18.04+/Centos 7+
#	Author:	gnotihz
#	Dscription: Xray OneKey Management
#	email: co@live.hk
#====================================================

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
stty erase ^?

cd "$(
    cd "$(dirname "$0")" || exit
    pwd
)" || exit

#fonts color
Green="\033[32m"
Red="\033[31m"
GreenW="\033[1;32m"
RedW="\033[1;31m"
#Yellow="\033[33m"
GreenBG="\033[42;30m"
RedBG="\033[41;30m"
YellowBG="\033[43;30m"
Font="\033[0m"

#notification information
# Info="${Green}[信息]${Font}"
OK="${Green}[OK]${Font}"
Error="${RedW}[错误]${Font}"
Warning="${RedW}[警告]${Font}"

list() {
    case $1 in
    '-1' | '--install-tls')
        shell_mode="Nginx+ws+TLS"
        tls_mode="TLS"
        install_xray_ws_tls
        ;;
    '-2' | '--install-xtls')
        shell_mode="XTLS+Nginx"
        tls_mode="XTLS"
        install_xray_xtls
        ;;
    '-3' | '--install-none')
        echo -e "\n${Warning} ${YellowBG} 此模式推荐用于负载均衡, 一般情况不推荐使用, 是否安装 [Y/${Red}N${Font}${YellowBG}]? ${Font}"
        read -r wsonly_fq
        case $wsonly_fq in
        [yY][eE][sS] | [yY])
            shell_mode="ws ONLY"
            tls_mode="None"
            install_xray_ws_only
            ;;
        *) ;;
        esac
        ;;
    '-4' | '--add-upstream')
        nginx_upstream_server_set
        ;;
    '-au' | '--auto-update')
        auto_update
        ;;
    '-c' | '--clean-logs')
        clean_logs
        ;;
    '-cs' | '--cert-status')
        check_cert_status
        ;;
    '-cu' | '--cert-update')
        service_stop
        cert_update_manuel
        service_restart
        ;;
    '-cau' | '--cert-auto-update')
        acme_cron_update
        ;;
    '-f' | '--set-fail2ban')
        network_secure
        ;;
    '-h' | '--help')
        show_help
        ;;
    '-n' | '--nginx-update')
        [[ $2 == "auto_update" ]] && auto_update="YES" && log_file="${log_dir}/auto_update.log"
        nginx_update
        ;;
    '-p' | '--port-set')
        revision_port
        firewall_set
        service_restart
        ;;
    '--purge' | '--uninstall')
        uninstall_all
        ;;
    '-s' | '-show')
        clear
        basic_information
        vless_qr_link_image
        show_information
        ;;
    '-tcp' | '--tcp')
        bbr_boost_sh
        ;;
    '-tls' | '--tls')
        tls_type
        ;;
    '-u' | '--update')
        [[ $2 == "auto_update" ]] && auto_update="YES" && log_file="${log_dir}/auto_update.log"
        update_sh
        ;;
    '-uu' | '--uuid-set')
        UUID_set
        modify_UUID
        service_restart
        ;;
    '-xa' | '--xray-access')
        clear
        show_access_log
        ;;
    '-xe' | '--xray-error')
        clear
        show_error_log
        ;;
    '-x' | '--xray-update')
        [[ $2 == "auto_update" ]] && auto_update="YES" && log_file="${log_dir}/auto_update.log"
        xray_update
        ;;
    *)
        menu
        ;;
    esac
}

show_help() {
    echo "usage: idleleo [OPTION]"
    echo
    echo 'OPTION:'
    echo '  -1, --install-tls           安装 Xray (Nginx+ws/gRPC+tls)'
    echo '  -2, --install-xtls          安装 Xray (XTLS+Nginx+ws/gRPC)'
    echo '  -3, --install-none          安装 Xray (ws/gRPC ONLY)'
    echo '  -4, --add-upstream          变更 Nginx 负载均衡配置'
    echo '  -au, --auto-update          设置自动更新'
    echo '  -c, --clean-logs            清除日志文件'
    echo '  -cs, --cert-status          查看证书状态'
    echo '  -cu, --cert-update          更新证书有效期'
    echo '  -cau, --cert-auto-update    设置证书自动更新'
    echo '  -f, --set-fail2ban          设置 Fail2ban 防暴力破解'
    echo '  -h, --help                  显示帮助'
    echo '  -n, --nginx-update          更新 Nginx'
    echo '  -p, --port-set              变更 port'
    echo '  --purge, --uninstall        脚本卸载'
    echo '  -s, --show                  显示安装信息'
    echo '  -tcp, --tcp                 配置 TCP 加速'
    echo '  -tls, --tls                 修改 TLS 配置'
    echo '  -u, --update                升级脚本'
    echo '  -uu, --uuid-set             变更 UUIDv5/映射字符串'
    echo '  -xa, --xray-access          显示 Xray 访问信息'
    echo '  -xe, --xray-error           显示 Xray 错误信息'
    echo '  -x, --xray-update           更新 Xray'
    exit 0
}

menu() {

    echo -e "\nXray 安装管理脚本 ${Red}[${shell_version}]${Font} ${shell_emoji}"
    echo -e "--- authored by paniy ---"
    echo -e "--- changed by www.idleleo.com ---"
    echo -e "--- https://github.com/paniy ---\n"
    echo -e "当前模式: ${shell_mode}\n"

    echo -e "可以使用${RedW} idleleo ${Font}命令管理脚本${Font}\n"

    echo -e "—————————————— ${GreenW}版本检测${Font} ——————————————"
    echo -e "脚本:  ${shell_need_update}"
    echo -e "Xray:  ${xray_need_update}"
    echo -e "Nginx: ${nginx_need_update}"
    echo -e "—————————————— ${GreenW}运行状态${Font} ——————————————"
    echo -e "Xray:   ${xray_status}"
    echo -e "Nginx:  ${nignx_status}"
    echo -e "连通性: ${xray_local_connect_status}"
    echo -e "—————————————— ${GreenW}升级向导${Font} ——————————————"
    echo -e "${Green}0.${Font}  升级 脚本"
    echo -e "${Green}1.${Font}  升级 Xray"
    echo -e "${Green}2.${Font}  升级 Nginx"
    echo -e "—————————————— ${GreenW}安装向导${Font} ——————————————"
    echo -e "${Green}3.${Font}  安装 Xray (Nginx+ws/gRPC+tls)"
    echo -e "${Green}4.${Font}  安装 Xray (XTLS+Nginx+ws/gRPC)"
    echo -e "${Green}5.${Font}  安装 Xray (ws/gRPC ONLY)"
    echo -e "—————————————— ${GreenW}配置变更${Font} ——————————————"
    echo -e "${Green}6.${Font}  变更 UUIDv5/映射字符串"
    echo -e "${Green}7.${Font}  变更 port"
    echo -e "${Green}8.${Font}  变更 TLS 版本"
    echo -e "${Green}9.${Font}  变更 Nginx 负载均衡配置"
    echo -e "—————————————— ${GreenW}用户管理${Font} ——————————————"
    echo -e "${Green}10.${Font} 查看 Xray 用户"
    echo -e "${Green}11.${Font} 添加 Xray 用户"
    echo -e "${Green}12.${Font} 删除 Xray 用户"
    echo -e "—————————————— ${GreenW}查看信息${Font} ——————————————"
    echo -e "${Green}13.${Font} 查看 Xray 实时访问日志"
    echo -e "${Green}14.${Font} 查看 Xray 实时错误日志"
    echo -e "${Green}15.${Font} 查看 Xray 配置信息"
    echo -e "—————————————— ${GreenW}服务相关${Font} ——————————————"
    echo -e "${Green}16.${Font} 重启 所有服务"
    echo -e "${Green}17.${Font} 启动 所有服务"
    echo -e "${Green}18.${Font} 停止 所有服务"
    echo -e "${Green}19.${Font} 查看 所有服务"
    echo -e "—————————————— ${GreenW}证书相关${Font} ——————————————"
    echo -e "${Green}20.${Font} 查看 证书状态"
    echo -e "${Green}21.${Font} 设置 证书自动更新"
    echo -e "${Green}22.${Font} 更新 证书有效期"
    echo -e "—————————————— ${GreenW}其他选项${Font} ——————————————"
    echo -e "${Green}23.${Font} 配置 自动更新"
    echo -e "${Green}24.${Font} 设置 TCP 加速"
    echo -e "${Green}25.${Font} 设置 Fail2ban 防暴力破解"
    echo -e "${Green}26.${Font} 设置 Xray 流量统计"
    echo -e "${Green}27.${Font} 清除 日志文件"
    echo -e "${Green}28.${Font} 测试 服务器网速"
    echo -e "—————————————— ${GreenW}卸载向导${Font} ——————————————"
    echo -e "${Green}29.${Font} 卸载 脚本"
    echo -e "${Green}30.${Font} 清空 证书文件"
    echo -e "${Green}31.${Font} 退出 \n"

    read -rp "请输入数字: " menu_num
    case $menu_num in
    0)
        update_sh
        bash idleleo
        ;;
    1)
        xray_update
        timeout "清空屏幕!"
        clear
        bash idleleo
        ;;
    2)
        nginx_update
        timeout "清空屏幕!"
        clear
        bash idleleo
        ;;
    3)
        shell_mode="Nginx+ws+TLS"
        tls_mode="TLS"
        install_xray_ws_tls
        bash idleleo
        ;;
    4)
        shell_mode="XTLS+Nginx"
        tls_mode="XTLS"
        install_xray_xtls
        bash idleleo
        ;;
    5)
        echo -e "\n${Warning} ${YellowBG} 此模式推荐用于负载均衡, 一般情况不推荐使用, 是否安装 [Y/${Red}N${Font}${YellowBG}]? ${Font}"
        read -r wsonly_fq
        case $wsonly_fq in
        [yY][eE][sS] | [yY])
            shell_mode="ws ONLY"
            tls_mode="None"
            install_xray_ws_only
            ;;
        *) ;;
        esac
        bash idleleo
        ;;
    6)
        UUID_set
        modify_UUID
        service_restart
        vless_qr_link_image
        timeout "清空屏幕!"
        clear
        menu
        ;;
    7)
        revision_port
        firewall_set
        service_restart
        vless_qr_link_image
        timeout "清空屏幕!"
        clear
        menu
        ;;
    8)
        tls_type
        timeout "清空屏幕!"
        clear
        menu
        ;;
    9)
        nginx_upstream_server_set
        timeout "清空屏幕!"
        clear
        menu
        ;;
    10)
        show_user
        timeout "回到菜单!"
        menu
        ;;
    11)
        add_user
        timeout "回到菜单!"
        menu
        ;;
    12)
        remove_user
        timeout "回到菜单!"
        menu
        ;;
    13)
        clear
        show_access_log
        ;;
    14)
        clear
        show_error_log
        ;;
    15)
        clear
        basic_information
        vless_qr_link_image
        show_information
        menu
        ;;
    16)
        service_restart
        timeout "清空屏幕!"
        clear
        menu
        ;;
    17)
        service_start
        timeout "清空屏幕!"
        clear
        bash idleleo
        ;;
    18)
        service_stop
        timeout "清空屏幕!"
        clear
        bash idleleo
        ;;
    19)
        if [[ ${tls_mode} != "None" ]]; then
            systemctl status nginx
        fi
        systemctl status xray
        menu
        ;;
    20)
        check_cert_status
        timeout "回到菜单!"
        menu
        ;;
    21)
        acme_cron_update
        timeout "清空屏幕!"
        clear
        menu
        ;;
    22)
        service_stop
        cert_update_manuel
        service_start
        menu
        ;;
    23)
        auto_update
        timeout "清空屏幕!"
        clear
        menu
        ;;
    24)
        clear
        bbr_boost_sh
        ;;
    25)
        network_secure
        menu
        ;;
    26)
        xray_status_add
        timeout "回到菜单!"
        menu
        ;;
    27)
        clean_logs
        menu
        ;;
    28)
        clear
        bash <(curl -Lso- https://git.io/Jlkmw)
        ;;
    29)
        uninstall_all
        timeout "清空屏幕!"
        clear
        bash idleleo
        ;;
    30)
        delete_tls_key_and_crt
        rm -rf ${ssl_chainpath}/*
        timeout "清空屏幕!"
        clear
        menu
        ;;
    31)
        timeout "清空屏幕!"
        clear
        exit 0
        ;;
    *)
        clear
        echo -e "${Error} ${RedBG} 请输入正确的数字! ${Font}"
        menu
        ;;
    esac
}

list "$@"

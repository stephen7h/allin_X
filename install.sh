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

list "$@"

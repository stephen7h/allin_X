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

shell_version="1.9.3.6"
shell_mode="未安装"
tls_mode="None"
ws_grpc_mode="None"
yzto_dir="/etc/yzto"
yzto_conf_dir="${yzto_dir}/conf"
log_dir="${yzto_dir}/logs"
xray_conf_dir="${yzto_conf_dir}/xray"
nginx_conf_dir="${yzto_conf_dir}/nginx"
xray_conf="${xray_conf_dir}/config.json"
xray_status_conf="${xray_conf_dir}/status_config.json"
xray_default_conf="/usr/local/etc/xray/config.json"
nginx_conf="${nginx_conf_dir}/xray.conf"
nginx_upstream_conf="${nginx_conf_dir}/xray-server.conf"
yzto_command_file="/usr/bin/yzto"
ssl_chainpath="${yzto_dir}/cert"
nginx_dir="/etc/nginx"
nginx_openssl_src="/usr/local/src"
xray_info_file="${yzto_dir}/info/xray_info.inf"
xray_qr_config_file="${yzto_dir}/info/vless_qr.json"
nginx_systemd_file="/etc/systemd/system/nginx.service"
xray_systemd_file="/etc/systemd/system/xray.service"
xray_access_log="/var/log/xray/access.log"
xray_error_log="/var/log/xray/error.log"
amce_sh_file="/root/.acme.sh/acme.sh"
auto_update_file="${yzto_dir}/auto_update.sh"
ssl_update_file="${yzto_dir}/ssl_update.sh"
cert_group="nobody"
myemali="my@example.com"
shell_version_tmp="${yzto_dir}/tmp/shell_version.tmp"
get_versions_all=$(curl -s https://www.yzto.com/api/xray_shell_versions)
bt_nginx="None"
read_config_status=1
xtls_add_more="off"
old_config_status="off"
old_tls_mode="NULL"
random_num=$((RANDOM % 12 + 4))
THREAD=$(($(grep 'processor' /proc/cpuinfo | sort -u | wc -l) + 1))
[[ -f ${xray_qr_config_file} ]] && info_extraction_all=$(jq -rc . ${xray_qr_config_file})

##兼容代码，未来删除
[[ ! -d "${yzto_dir}/tmp" ]] && mkdir -p ${yzto_dir}/tmp

source '/etc/os-release'

VERSION=$(echo "${VERSION}" | awk -F "[()]" '{print $2}')


timeout() {
    timeout=0
    timeout_str=""
    while [[ ${timeout} -le 30 ]]; do
        let timeout++
        timeout_str+="#"
    done
    let timeout=timeout+5
    while [[ ${timeout} -gt 0 ]]; do
        let timeout--
        if [[ ${timeout} -gt 25 ]]; then
            let timeout_color=32
            let timeout_bg=42
            timeout_index="3"
        elif [[ ${timeout} -gt 15 ]]; then
            let timeout_color=33
            let timeout_bg=43
            timeout_index="2"
        elif [[ ${timeout} -gt 5 ]]; then
            let timeout_color=31
            let timeout_bg=41
            timeout_index="1"
        else
            timeout_index="0"
        fi
        printf "${Warning} ${GreenBG} %d秒后将$1 ${Font} \033[${timeout_color};${timeout_bg}m%-s\033[0m \033[${timeout_color}m%d\033[0m \r" "$timeout_index" "$timeout_str" "$timeout_index"
        sleep 0.1
        timeout_str=${timeout_str%?}
        [[ ${timeout} -eq 0 ]] && printf "\n"
    done
}

install_xray_ws_tls() {
    is_root
    check_system
    dependency_install
    basic_optimization
    create_directory
    old_config_exist_check
    domain_check
    ws_grpc_choose
    port_set
    ws_inbound_port_set
    grpc_inbound_port_set
    firewall_set
    ws_path_set
    grpc_path_set
    email_set
    UUID_set
    ws_grpc_qr
    vless_qr_config_tls_ws
    stop_service_all
    xray_install
    port_exist_check 80
    port_exist_check "${port}"
    nginx_exist_check
    xray_conf_add
    nginx_conf_add
    nginx_conf_servers_add
    web_camouflage
    ssl_judge_and_install
    nginx_systemd
    tls_type
    basic_information
    service_restart
    enable_process_systemd
    acme_cron_update
    auto_update
    vless_link_image_choice
    show_information
}

install_xray_xtls() {
    is_root
    check_system
    dependency_install
    basic_optimization
    create_directory
    old_config_exist_check
    domain_check
    port_set
    email_set
    UUID_set
    xray_xtls_add_more_choose
    ws_grpc_qr
    firewall_set
    vless_qr_config_xtls
    stop_service_all
    xray_install
    port_exist_check 80
    port_exist_check "${port}"
    nginx_exist_check
    nginx_conf_add_xtls
    xray_conf_add
    ssl_judge_and_install
    nginx_systemd
    tls_type
    basic_information
    service_restart
    enable_process_systemd
    acme_cron_update
    auto_update
    vless_link_image_choice
    show_information
}

install_xray_ws_only() {
    is_root
    check_system
    dependency_install
    basic_optimization
    create_directory
    old_config_exist_check
    ip_check
    ws_grpc_choose
    ws_inbound_port_set
    grpc_inbound_port_set
    firewall_set
    ws_path_set
    grpc_path_set
    email_set
    UUID_set
    ws_grpc_qr
    vless_qr_config_ws_only
    stop_service_all
    xray_install
    port_exist_check "${xport}"
    port_exist_check "${gport}"
    xray_conf_add
    basic_information
    service_restart
    enable_process_systemd
    auto_update
    vless_link_image_choice
    show_information
}

update_sh() {
    ol_version=${shell_online_version}
    echo "${ol_version}" >${shell_version_tmp}
    [[ -z ${ol_version} ]] && echo -e "${Error} ${RedBG}  检测最新版本失败! ${Font}" && return 1
    echo "${shell_version}" >>${shell_version_tmp}
    newest_version=$(sort -rV ${shell_version_tmp} | head -1)
    oldest_version=$(sort -V ${shell_version_tmp} | head -1)
    version_difference=$(echo "(${newest_version:0:3}-${oldest_version:0:3})>0" | bc)
    if [[ ${shell_version} != ${newest_version} ]]; then
        if [[ ${auto_update} != "YES" ]]; then
            if [[ ${version_difference} == 1 ]]; then
                echo -e "\n${Warning} ${YellowBG} 存在新版本, 但版本跨度较大, 可能存在不兼容情况, 是否更新 [Y/${Red}N${Font}${YellowBG}]? ${Font}"
            else
                echo -e "\n${GreenBG} 存在新版本, 是否更新 [Y/${Red}N${Font}${GreenBG}]? ${Font}"
            fi
            read -r update_confirm
        else
            [[ -z ${ol_version} ]] && echo "检测 脚本 最新版本失败!" >>${log_file} && exit 1
            [[ ${version_difference} == 1 ]] && echo "脚本 版本差别过大, 跳过更新!" >>${log_file} && exit 1
            update_confirm="YES"
        fi
        case $update_confirm in
        [yY][eE][sS] | [yY])
            [[ -L ${idleleo_commend_file} ]] && rm -f ${idleleo_commend_file}
            wget -N --no-check-certificate -P ${idleleo_dir} https://raw.githubusercontent.com/paniy/Xray_bash_onekey/main/install.sh && chmod +x ${idleleo_dir}/install.sh
            ln -s ${idleleo_dir}/install.sh ${idleleo_commend_file}
            clear
            echo -e "${OK} ${GreenBG} 更新完成 ${Font}"
            [[ ${version_difference} == 1 ]] && echo -e "${Warning} ${YellowBG} 脚本版本跨度较大, 若服务无法正常运行请卸载后重装! ${Font}"
            ;;
        *) ;;
        esac
    else
        clear
        echo -e "${OK} ${GreenBG} 当前版本为最新版本 ${Font}"
    fi

}

check_file_integrity() {
    if [[ ! -L ${yzto_command_file} ]] && [[ ! -f ${yzto_dir}/install.sh ]]; then
        check_system
        pkg_install "bc,jq,wget"
        [[ ! -d "${yzto_dir}" ]] && mkdir -p ${yzto_dir}
        [[ ! -d "${yzto_dir}/tmp" ]] && mkdir -p ${yzto_dir}/tmp
        wget -N --no-check-certificate -P ${yzto_dir} https://raw.githubusercontent.com/stephen7h/allin_X/main/install.sh && chmod +x ${yzto_dir}/install.sh
        judge "下载最新脚本"
        ln -s ${yzto_dir}/install.sh ${yzto_command_file}
        clear
        bash yzto
    fi
}

read_version() {
    shell_online_version="$(check_version shell_online_version)"
    xray_version="$(check_version xray_tested_version)"
    nginx_version="$(check_version nginx_online_version)"
    openssl_version="$(check_version openssl_online_version)"
    jemalloc_version="$(check_version jemalloc_tested_version)"
}

judge_mode() {
    if [[ -f ${xray_qr_config_file} ]]; then
        ws_grpc_mode=$(info_extraction ws_grpc_mode)
        tls_mode=$(info_extraction tls)
        bt_nginx=$(info_extraction bt_nginx)
        if [[ ${tls_mode} == "TLS" ]]; then
            [[ ${ws_grpc_mode} == "onlyws" ]] && shell_mode="Nginx+ws+TLS"
            [[ ${ws_grpc_mode} == "onlygRPC" ]] && shell_mode="Nginx+gRPC+TLS"
            [[ ${ws_grpc_mode} == "all" ]] && shell_mode="Nginx+ws+gRPC+TLS"
        elif [[ ${tls_mode} == "XTLS" ]]; then
            if [[ $(info_extraction xtls_add_more) != "off" ]]; then
                xtls_add_more="on"
                [[ ${ws_grpc_mode} == "onlyws" ]] && shell_mode="XTLS+Nginx+ws"
                [[ ${ws_grpc_mode} == "onlygRPC" ]] && shell_mode="XTLS+Nginx+gRPC"
                [[ ${ws_grpc_mode} == "all" ]] && shell_mode="XTLS+Nginx+ws+gRPC"
            else
                shell_mode="XTLS+Nginx"
            fi
        elif [[ ${tls_mode} == "None" ]]; then
            [[ ${ws_grpc_mode} == "onlyws" ]] && shell_mode="ws ONLY"
            [[ ${ws_grpc_mode} == "onlygRPC" ]] && shell_mode="gRPC ONLY"
            [[ ${ws_grpc_mode} == "all" ]] && shell_mode="ws+gRPC ONLY"
        fi
        [[ $(info_extraction xtls_add_more) == "on" ]] && xtls_add_more="on"
        old_tls_mode=${tls_mode}
    fi
}

maintain() {
    echo -e "${Error} ${RedBG} 该选项暂时无法使用! ${Font}"
    echo -e "${Error} ${RedBG} $1 ${Font}"
    exit 0
}

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
    echo "usage: yzto [OPTION]"
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

yzto_command() {
    if [[ -L ${yzto_command_file} ]] || [[ -f ${yzto_dir}/install.sh ]]; then
        ##在线运行与本地脚本比对
        [[ ! -L ${yzto_command_file} ]] && chmod +x ${yzto_dir}/install.sh && ln -s ${yzto_dir}/install.sh ${yzto_command_file}
        old_version=$(grep "shell_version=" ${yzto_dir}/install.sh | head -1 | awk -F '=|"' '{print $3}')
        echo "${old_version}" >${shell_version_tmp}
        echo "${shell_version}" >>${shell_version_tmp}
        oldest_version=$(sort -V ${shell_version_tmp} | head -1)
        version_difference=$(echo "(${shell_version:0:3}-${oldest_version:0:3})>0" | bc)
        if [[ -z ${old_version} ]]; then
            wget -N --no-check-certificate -P ${yzto_dir} https://raw.githubusercontent.com/stephen7h/allin_X/main/install.sh && chmod +x ${yzto_dir}/install.sh
            judge "下载最新脚本"
            clear
            bash yzto
        elif [[ ${shell_version} != ${oldest_version} ]]; then
            if [[ ${version_difference} == 1 ]]; then
                echo -e "${Warning} ${YellowBG} 脚本版本跨度较大, 可能存在不兼容情况, 是否继续使用 [Y/${Red}N${Font}${YellowBG}]? ${Font}"
                read -r update_sh_fq
                case $update_sh_fq in
                [yY][eE][sS] | [yY])
                    rm -rf ${yzto_dir}/install.sh
                    wget -N --no-check-certificate -P ${yzto_dir} https://raw.githubusercontent.com/stephen7h/allin_X/main/install.sh && chmod +x ${yzto_dir}/install.sh
                    judge "下载最新脚本"
                    clear
                    echo -e "${Warning} ${YellowBG} 脚本版本跨度较大, 若服务无法正常运行请卸载后重装!\n ${Font}"
                    ;;
                *)
                    bash yzto
                    ;;
                esac
            else
                rm -rf ${yzto_dir}/install.sh
                wget -N --no-check-certificate -P ${yzto_dir} https://raw.githubusercontent.com/stephen7h/allin_X/main/install.sh && chmod +x ${yzto_dir}/install.sh
                judge "下载最新脚本"
                clear
            fi
            bash yzto
        else
            ol_version=${shell_online_version}
            echo "${ol_version}" >${shell_version_tmp}
            [[ -z ${ol_version} ]] && shell_need_update="${Red}[检测失败!]${Font}"
            echo "${shell_version}" >>${shell_version_tmp}
            newest_version=$(sort -rV ${shell_version_tmp} | head -1)
            if [[ ${shell_version} != ${newest_version} ]]; then
                shell_need_update="${Red}[有新版!]${Font}"
                shell_emoji="${Red}>_<${Font}"
            else
                shell_need_update="${Green}[最新版]${Font}"
                shell_emoji="${Green}^O^${Font}"
            fi
            if [[ -f ${xray_qr_config_file} ]]; then
                if [[ $(info_extraction nginx_version) == null ]] || [[ ! -f "${nginx_dir}/sbin/nginx" ]]; then
                    nginx_need_update="${Red}[未安装]${Font}"
                elif [[ ${nginx_version} != $(info_extraction nginx_version) ]] || [[ ${openssl_version} != $(info_extraction openssl_version) ]] || [[ ${jemalloc_version} != $(info_extraction jemalloc_version) ]]; then
                    nginx_need_update="${Red}[有新版!]${Font}"
                else
                    nginx_need_update="${Green}[最新版]${Font}"
                fi
                if [[ -f ${xray_qr_config_file} ]] && [[ -f ${xray_conf} ]] && [[ -f /usr/local/bin/xray ]]; then
                    xray_online_version=$(check_version xray_online_version)
                    if [[ $(info_extraction xray_version) == null ]]; then
                        xray_need_update="${Green}[已安装] (版本未知)${Font}"
                    elif [[ ${xray_version} != $(info_extraction xray_version) ]] && [[ $(info_extraction xray_version) != ${xray_online_version} ]]; then
                        xray_need_update="${Red}[有新版!]${Font}"
                    elif [[ ${xray_version} == $(info_extraction xray_version) ]] || [[ $(info_extraction xray_version) == ${xray_online_version} ]]; then
                        if [[ $(info_extraction xray_version) != ${xray_online_version} ]]; then
                            xray_need_update="${Green}[有测试版]${Font}"
                        else
                            xray_need_update="${Green}[最新版]${Font}"
                        fi
                    fi
                else
                    xray_need_update="${Red}[未安装]${Font}"
                fi
            else
                nginx_need_update="${Red}[未安装]${Font}"
                xray_need_update="${Red}[未安装]${Font}"
            fi
        fi
    fi
}

check_program() {
    if [[ -n $(pgrep nginx) ]]; then
        nignx_status="${Green}运行中..${Font}"
    else
        nignx_status="${Red}未运行${Font}"
    fi
    if [[ -n $(pgrep xray) ]]; then
        xray_status="${Green}运行中..${Font}"
    else
        xray_status="${Red}未运行${Font}"
    fi
}

curl_local_connect() {
    curl -Is -o /dev/null -w %{http_code} "https://$1/$2"
}

check_xray_local_connect() {
    if [[ -f ${xray_qr_config_file} ]]; then
        xray_local_connect_status="${Red}无法连通${Font}"
        if [[ ${tls_mode} == "TLS" ]]; then
            [[ ${ws_grpc_mode} == "onlyws" ]] && [[ $(curl_local_connect $(info_extraction host) $(info_extraction path)) == "400" ]] && xray_local_connect_status="${Green}本地正常${Font}"
            [[ ${ws_grpc_mode} == "onlygrpc" ]] && [[ $(curl_local_connect $(info_extraction host) $(info_extraction servicename)) == "502" ]] && xray_local_connect_status="${Green}本地正常${Font}"
            [[ ${ws_grpc_mode} == "all" ]] && [[ $(curl_local_connect $(info_extraction host) $(info_extraction servicename)) == "502" && $(curl_local_connect $(info_extraction host) $(info_extraction path)) == "400" ]] && xray_local_connect_status="${Green}本地正常${Font}"
        elif [[ ${tls_mode} == "XTLS" ]]; then
            [[ $(curl_local_connect $(info_extraction host)) == "302" ]] && xray_local_connect_status="${Green}本地正常${Font}"
        elif [[ ${tls_mode} == "None" ]]; then
            xray_local_connect_status="${Green}无需测试${Font}"
        fi
    else
        xray_local_connect_status="${Red}未安装${Font}"
    fi
}

menu() {

    echo -e "\nXray 安装管理脚本 ${Red}[${shell_version}]${Font} ${shell_emoji}\n"
    echo -e "当前模式: ${shell_mode}\n"
    echo -e "可以使用${RedW} yzto ${Font}命令管理脚本${Font}\n"

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
        bash yzto
        ;;
    1)
        xray_update
        timeout "清空屏幕!"
        clear
        bash yzto
        ;;
    2)
        nginx_update
        timeout "清空屏幕!"
        clear
        bash yzto
        ;;
    3)
        shell_mode="Nginx+ws+TLS"
        tls_mode="TLS"
        install_xray_ws_tls
        bash yzto
        ;;
    4)
        shell_mode="XTLS+Nginx"
        tls_mode="XTLS"
        install_xray_xtls
        bash yzto
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
        bash yzto
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
        bash yzto
        ;;
    18)
        service_stop
        timeout "清空屏幕!"
        clear
        bash yzto
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
        bash yzto
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

check_file_integrity
read_version
judge_mode
yzto_command
check_program
check_xray_local_connect
list "$@"

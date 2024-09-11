#!/bin/bash

WORKDIR=$(dirname $(readlink -f $0))
cd $WORKDIR
pid_file=$WORKDIR/pid/pid_mtproxy

# 固定密钥和端口
secret="4451023506896290666356006a67ce93" # 替换为你的固定密钥
port=8443 # 固定端口
web_port=8888

check_sys() {
    local checkType=$1
    local value=$2
    local release=''
    local systemPackage=''
    # 系统检查部分未改动...

do_install_basic_dep() {
    if check_sys packageManager yum; then
        yum install -y iproute curl wget procps-ng.x86_64 net-tools ntp
    elif check_sys packageManager apt; then
        apt install -y iproute2 curl wget procps net-tools ntpdate
    fi

    return 0
}

do_install() {
    cd $WORKDIR

    mtg_provider=$(get_mtg_provider)

    if [[ "$mtg_provider" == "mtg" ]]; then
        local arch=$(get_architecture)
        local mtg_url=https://github.com/9seconds/mtg/releases/download/v1.0.11/mtg-1.0.11-linux-$arch.tar.gz
        wget $mtg_url -O mtg.tar.gz
        tar -xzvf mtg.tar.gz mtg-1.0.11-linux-$arch/mtg --strip-components 1

        [[ -f "./mtg" ]] && ./mtg && echo "Installed for mtg"
    else
        wget https://github.com/ellermister/mtproxy/releases/download/0.03/mtproto-proxy -O mtproto-proxy -q
        chmod +x mtproto-proxy
    fi

    if [ ! -d "./pid" ]; then
        mkdir "./pid"
    fi
}

run_mtp() {
    cd $WORKDIR

    if is_running_mtp; then
        echo -e "提醒：\033[33mMTProxy已经运行，请勿重复运行!\033[0m"
    else
        do_kill_process
        do_check_system_datetime_and_update

        local command=$(get_run_command)
        echo $command
        $command >/dev/null 2>&1 &

        echo $! >$pid_file
        sleep 2
        info_mtp
    fi
}

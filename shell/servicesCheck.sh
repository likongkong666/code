#!/bin/bash

# 配置文件路径
CONFIG_FILE=${1:-"services.conf"}

# 检查配置文件是否存在
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "配置文件 $CONFIG_FILE 不存在"
    exit 1
fi

# 读取配置文件并监控每个服务
while IFS=',' read -r SERVICE_NAME PORT LOG_FILE ERROR_KEYWORD; do
    # 跳过空行和注释
    [[ -z "$SERVICE_NAME" || "$SERVICE_NAME" =~ ^# ]] && continue

    # 初始化状态
    STATUS="OK"
    REASON=""

    # 检查端口是否正常
    check_port() {
        nc -z localhost "$PORT"
        return $?
    }

    # 检查进程是否正常
    check_process() {
        pgrep -f "$SERVICE_NAME" > /dev/null
        return $?
    }

    # 检查日志是否正常
    check_log() {
        if grep -q "$ERROR_KEYWORD" "$LOG_FILE"; then
            return 1  # 如果日志中有错误，则返回 1
        else
            return 0  # 否则返回 0
        fi
    }

    # 执行检查
    check_port
    PORT_STATUS=$?
    if [ $PORT_STATUS -ne 0 ]; then
        STATUS="FAIL"
        REASON+="端口 $PORT 不可用; "
    fi

    check_process
    PROCESS_STATUS=$?
    if [ $PROCESS_STATUS -ne 0 ]; then
        STATUS="FAIL"
        REASON+="服务 $SERVICE_NAME 未运行; "
    fi

    check_log
    LOG_STATUS=$?
    if [ $LOG_STATUS -ne 0 ]; then
        STATUS="FAIL"
        REASON+="日志 $LOG_FILE 中发现错误关键字 \"$ERROR_KEYWORD\"; "
    fi

    # 输出结果
    if [ "$STATUS" == "OK" ]; then
        echo "$SERVICE_NAME: OK"
    else
        echo "$SERVICE_NAME: FAIL - $REASON"
    fi
done < "$CONFIG_FILE"



# 示例配置文件内容
# 服务名称,端口,日志文件路径,错误关键字
# service1,8080,/var/log/service1.log,ERROR
# service2,8081,/var/log/service2.log,ERROR
# service3,8082,/var/log/service3.log,ERROR
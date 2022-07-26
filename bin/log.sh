LOG() {
    printf '[%s] %s\n' "$(date +"%H:%M:%S")" "$1"
}

LOGI() {
    printf '[%s] \033[94m[INFO]\033[0m%s\n' "$(date +"%H:%M:%S")" "$1"
}

LOGE() {
    printf '[%s] \033[91m[ERROR]\033[0m%s\n' "$(date +"%H:%M:%S")" "$1" 1>&2
}

LOGW() {
    printf '[%s] \033[93m[WARNING]\033[0m%s\n' "$(date +"%H:%M:%S")" "$1" 1>&2
}

LOGS() {
    printf '[%s] \033[92m[SUCCESS]\033[0m%s\n' "$(date +"%H:%M:%S")" "$1"
}
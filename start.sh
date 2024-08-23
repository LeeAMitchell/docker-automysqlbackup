#!/bin/bash

set -e

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
        local var="$1"
        local fileVar="${var}_FILE"
        local def="${2:-}"
        if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
                echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
                exit 1
        fi
        local val="$def"
        if [ "${!var:-}" ]; then
                val="${!var}"
        elif [ "${!fileVar:-}" ]; then
                val="$(< "${!fileVar}")"
        fi
        export "$var"="$val"
        unset "$fileVar"
}

# Get PASSWORD from PASSWORD_FILE if available
file_env 'PASSWORD'

# Get USERNAME from USERNAME_FILE if availabile
file_env 'USERNAME'

: "${USER_ID:=0}"
: "${GROUP_ID:=0}"

chown --dereference $USER_ID "/proc/$$/fd/1" "/proc/$$/fd/2" || :

if [ "${CRON_SCHEDULE}" ]; then
    exec gosu $USER_ID:$GROUP_ID go-cron -s "0 ${CRON_SCHEDULE}" -- automysqlbackup
else
    exec gosu $USER_ID:$GROUP_ID bash /usr/local/bin/automysqlbackup
fi

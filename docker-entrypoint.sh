#!/bin/sh

set -e

if [ -z "${USER}" ]; then
    echo "We need USER to be set!"; exit 100
fi

# if both not set we do not need to do anything
if [ -z "${HOST_USER_ID}" -a -z "${HOST_USER_GID}" ]; then
    echo "Nothing to do here." ; exit 0
fi

# reset user_id to either new id or if empty old (still one of above might not be set)
USER_ID=${HOST_USER_ID:=$USER_ID}
USER_GID=${HOST_USER_GID:=$USER_GID}

# change user passwd
sed -i -e "s/^${USER}:\([^:]*\):[0-9]*:[0-9]*/${USER}:\1:${USER_ID}:${USER_GID}/"  /etc/passwd
sed -i -e "s/^${USER}:\([^:]*\):[0-9]*/${USER}:\1:${USER_GID}/"  /etc/group

# reset homedir permissions
chown -R ${USER_ID}:${USER_GID} /home/$USER
find /home/$USER -type d -exec chmod 775 {} + # directories
find /home/$USER -type f -exec chmod 664 {} + # files

# reset appdir permissions
chown -R ${USER_ID}:${USER_GID} $APPDIR
find $APPDIR -type d -exec chmod 775 {} + # directories
find $APPDIR -type f -exec chmod 664 {} + # files

exec "$@"

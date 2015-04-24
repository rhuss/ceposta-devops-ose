#!/bin/bash

set -e

#
# Discover the APP_BASE from the location of this script.
#
if [ -z "$APP_BASE" ] ; then
  ## resolve links - $0 may be a link to apollo's home
  PRG="$0"
  saveddir=`pwd`

  # need this for relative symlinks
  dirname_prg=`dirname "$PRG"`
  cd "$dirname_prg"

  while [ -h "$PRG" ] ; do
    ls=`ls -ld "$PRG"`
    link=`expr "$ls" : '.*-> \(.*\)$'`
    if expr "$link" : '.*/.*' > /dev/null; then
      PRG="$link"
    else
      PRG=`dirname "$PRG"`"/$link"
    fi
  done

  APP_BASE=`dirname "$PRG"`
  cd "$saveddir"

  # make it fully qualified
  APP_BASE=`cd "$APP_BASE/.." && pwd`
  export APP_BASE
fi

# environment variables
GITLAB_USER=${GITLAB_USER:-root}
GITLAB_PASSWORD=${GITLAB_PASSWORD:-redhat01}
GITLAB_PROJ_ROOT=${GITLAB_PROJ_ROOT:-root}
GITLAB_VERSION=${GITLAB_VERSION:-7.9.4}

echo "Creating the docker images using gitlab user ${GITLAB_USER} and project root '${GITLAB_PROJ_ROOT}'"
docker run -itdP --name mysql -v /opt/gitlab/mysql:/var/lib/mysql -e 'DB_NAME=gitlabhq_production' -e 'DB_USER=gitlab' -e 'DB_PASS=password' sameersbn/mysql:latest
docker run -itdP --name redis sameersbn/redis
docker run -itdP --name gitlab -v /opt/gitlab/mysql:/var/lib/mysql -e 'DB_HOST=192.168.59.103' -e 'DB_NAME=gitlabhq_production' -e 'DB_USER=gitlab' -e 'DB_PASS=redhat01' -e 'GITLAB_SIGNUP=true' -e 'GITLAB_SSH_PORT=10022' -e 'GITLAB_PORT=10080' -p 10022:22 -p 10080:80 --env GITLAB_ROOT_PASSWORD=$GITLAB_PASSWORD --link redis:redisio --link mysql:mysql --privileged sameersbn/gitlab:$GITLAB_VERSION

docker run -itdP --name gerrit --env GITLAB_USER=$GITLAB_USER --env GITLAB_PASSWORD=$GITLAB_PASSWORD --env GITLAB_PROJ_ROOT=$GITLAB_PROJ_ROOT --link gitlab:gitlab fabric8:gerrit
docker run -itdP --name nexus pantinor/centos-nexus:latest
docker run -itdP --name jenkins --link gitlab:gitlab --link nexus:nexus --link gerrit:gerrit --privileged fabric8:jenkins

. $APP_BASE/bootstrap/print-docker.sh

#From the cmd line
#docker run -it --rm --volumes-from=mysql sameersbn/mysql:latest mysql -uroot
#mysql> CREATE USER 'gitlab'@'192.168.59.103' IDENTIFIED BY 'redhat01';
#mysql> SET storage_engine=INNODB;
#mysql> CREATE DATABASE IF NOT EXISTS `gitlabhq_production` DEFAULT CHARACTER SET `utf8` COLLATE `utf8_unicode_ci`;
#mysql> GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, LOCK TABLES ON `gitlabhq_production`.* TO 'gitlab'@'192.168.59.103';

#docker run -it --rm --volumes-from=mysql sameersbn/mysql:latest mysql -u gitlab -H mysql -u git -p -D gitlabhq_production

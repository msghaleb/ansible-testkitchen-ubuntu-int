#!/bin/sh
#TODO.md

YEL='\033[0;33m'
NC='\033[0m' # No Color

yum_makecache_retry() {
  tries=0
  until [ $tries -ge 5 ]
  do
    yum makecache && break
    let tries++
    sleep 1
  done
}

if [ "x$KITCHEN_LOG" = "xDEBUG" -o "x$OMNIBUS_ANSIBLE_LOG" = "xDEBUG" ]; then
  export PS4='(${BASH_SOURCE}:${LINENO}): - [${SHLVL},${BASH_SUBSHELL},$?] $ '
  set -x
fi

printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
echo "${YEL} checking if you run this script before ${NC}"
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -

if [ $(which ansible-playbook) ]; then
  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
  echo "${YEL} you did not .. we will check which linux destro are you running ${NC}"
  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
  if [ -f /etc/centos-release ] || [ -f /etc/redhat-release ] || [ -f /etc/oracle-release ] || [ -f /etc/system-release ] || grep -q 'Amazon Linux' /etc/system-release; then
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    echo "${YEL} RPM destro found ${NC}"
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    # Install required Python libs and pip
    # Fix EPEL Metalink SSL error
    # - workaround: https://community.hpcloud.com/article/centos-63-instance-giving-cannot-retrieve-metalink-repository-epel-error
    # - SSL secure solution: Update ca-certs!!
    #   - http://stackoverflow.com/q/26734777/645491#27667111
    #   - http://serverfault.com/q/637549/77156
    #   - http://unix.stackexchange.com/a/163368/7688
    yum -y install ca-certificates nss
    yum clean all
    rm -rf /var/cache/yum
    yum_makecache_retry
    yum -y install epel-release
    # One more time with EPEL to avoid failures
    yum_makecache_retry

    yum -y install python-pip PyYAML python-jinja2 python-httplib2 python-keyczar python-paramiko git
    # If python-pip install failed and setuptools exists, try that
    if [ -z "$(which pip)" -a -z "$(which easy_install)" ]; then
      yum -y install python-setuptools
      easy_install pip
    elif [ -z "$(which pip)" -a -n "$(which easy_install)" ]; then
      easy_install pip
    fi

    # Install passlib for encrypt
    yum -y groupinstall "Development tools"
    yum -y install python-devel MySQL-python sshpass && pip install pyrax pysphere boto passlib dnspython

    # Install Ansible module dependencies
    yum -y install bzip2 file findutils git gzip hg svn sudo tar which unzip xz zip libselinux-python
    [ -n "$(yum search procps-ng)" ] && yum -y install procps-ng || yum -y install procps
  elif [ -f /etc/debian_version ] || [ grep -qi ubuntu /etc/lsb-release ] || grep -qi ubuntu /etc/os-release; then
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    echo "${YEL} DEB destro found ${NC}"
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    echo "${YEL} updating the OS ${NC}"
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    apt-get update
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    echo "${YEL} upgrading the OS ${NC}"
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    apt-get upgrade -y
    # Install via package
    # apt-get update && \
    # apt-get install --no-install-recommends -y software-properties-common && \
    # apt-add-repository ppa:ansible/ansible && \
    # apt-get update && \
    # apt-get install -y ansible

    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    echo "${YEL} Installing required Python libs and pip ${NC}"
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    apt-get install -y python-pip python-yaml python-jinja2 python-httplib2 python-paramiko python-pkg-resources libffi-dev

    [ -n "$( apt-cache search python-keyczar )" ] && apt-get install -y  python-keyczar
    if ! apt-get install -y git ; then
      printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
      echo "${YEL} Installing Git ${NC}"
      printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
      apt-get install -y git-core
    fi
    # If python-pip install failed and setuptools exists, try that
    if [ -z "$(which pip)" -a -z "$(which easy_install)" ]; then
      printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
      echo "${YEL} Installing pip and python setup tools ${NC}"
      printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
      apt-get -y install python-setuptools
      easy_install pip
    elif [ -z "$(which pip)" -a -n "$(which easy_install)" ]; then
      printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
      echo "${YEL} Installing pip ${NC}"
      printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
      easy_install pip
    fi
    # If python-keyczar apt package does not exist, use pip
    [ -z "$( apt-cache search python-keyczar )" ] && sudo pip install python-keyczar

    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    echo "${YEL} upgrading pip and setuptools ${NC}"
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    pip install -U setuptools pip
    pip install -U pywinrm

    # Install passlib for encrypt
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    echo "${YEL} Installing build-essential and passlib for encrypt ${NC}"
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    apt-get install -y build-essential
    apt-get install -y python-all-dev python-mysqldb sshpass && pip install pyrax pysphere boto passlib dnspython

    # Install Ansible module dependencies
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    echo "${YEL} Installing ansible dependencies ${NC}"
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    apt-get install -y bzip2 file findutils git gzip mercurial procps subversion sudo tar debianutils unzip xz-utils zip python-selinux

    # install requiered ruby libs ..etc.
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    echo "${YEL} Installing ruby dependencies ${NC}"
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    apt-get install -y python-dev git-core curl libjpeg8-dev zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties nodejs

    # Install Test-Kitchen dependencies
    #printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    #echo "${YEL} Installing ruby dev tools ${NC}"
    #printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    #apt-get install -y ruby-all-dev

    mkdir /etc/ansible/
    echo -e '[local]\nlocalhost\n' > /etc/ansible/hosts

    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    echo "${YEL} Installing xmltodict ${NC}"
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    pip install -U xmltodict

    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    echo "${YEL} Installing ansible ${NC}"
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    pip install ansible

    # installing ruby
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    echo "${YEL} Installing Ruby ${NC}"
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    cd
    if [ ! $(which ansible-playbook) ]; then
      git clone https://github.com/rbenv/rbenv.git ~/.rbenv
    fi
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
    echo 'eval "$(rbenv init -)"' >> ~/.bashrc
    #exec $SHELL
    if [ ! $(which ansible-playbook) ]; then
      git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
    fi
    echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
    #exec $SHELL

    rbenv install 2.4.2
    rbenv global 2.4.2
    ruby -v

    #install Test-Kitchen
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    echo "${YEL} Installing Bundler ${NC}"
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    gem install bundler

    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    echo "${YEL} Installing Test-Kitchen ${NC}"
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    gem install test-kitchen
    gem install kitchen-ansible
    gem install kitchen-ansiblepush
    gem install winrm

    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    echo "${YEL} Cloning NGINX ${NC}"
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    git clone https://github.com/msghaleb/ansible-nginx.git
    #cd ansible-linux-nginx
    #printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    #echo "${YEL} Running bundler install ${NC}"
    #printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    #. bundler install

  else
    echo "${YEL} WARN: Could not detect distro or distro unsupported ${NC}"
    echo "${YEL} WARN: Trying to install ansible via pip without some dependencies ${NC}"
    echo "${YEL} WARN: Not all functionality of ansible may be available ${NC}"
  fi

  if [ -f /etc/centos-release ] || [ -f /etc/redhat-release ] || [ -f /etc/oracle-release ] || [ -f /etc/system-release ] || grep -q 'Amazon Linux' /etc/system-release; then
    # Fix for pycrypto pip / yum issue
    # https://github.com/ansible/ansible/issues/276
    if  ansible --version 2>&1  | grep -q "AttributeError: 'module' object has no attribute 'HAVE_DECL_MPZ_POWM_SEC'" ; then
      echo "${YEL} WARN: Re-installing python-crypto package to workaround ansible/ansible#276 ${NC}"
      echo "${YEL} WARN: https://github.com/ansible/ansible/issues/276 ${NC}"
      pip uninstall -y pycrypto
      yum erase -y python-crypto
      yum install -y python-crypto python-paramiko
    fi
  fi
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
echo "${YEL} you are all set .. bye bye ${NC}"
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -

else
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
echo "${YEL} you ran it before .. bye bye ${NC}"
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -

fi

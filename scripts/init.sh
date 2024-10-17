
get_info_field() {
    cat /etc/$1-release \
        | grep ^$2= \
        | sed 's/.*=//g; s/"//g'
}

get_distro_name() {
    get_info_field $1 NAME
}

get_distro_version() {
    get_info_field $1 DISTRO_VERSION
}

if [ -f "/etc/os-release" ]; then
    DISTRO_NAME=$(get_distro_name os)
    DISTRO_VERSION=$(get_distro_version os)
    echo $DISTRO_NAME
    #cat /etc/os-release
elif [ -f "/etc/lsb-release" ]; then
    DISTRO_NAME=$(get_distro_name lsb)
    #DISTRO_NAME=$DISTRIB_ID
    DISTRO_VERSION=$DISTRIB_RELEASE
    cat /etc/lsb-release
elif [ -f "/etc/redhat-release" ]; then
    DISTRO_NAME=$(cat /etc/redhat-release | awk '{print $1}')
    DISTRO_VERSION=$(cat /etc/redhat-release | awk '{print $3}')
else
    echo "Could not determine the distribution."
    exit 1
fi

#echo "\n\n\n\n"
#
#echo "Detected distribution: $DISTRO_NAME"
#echo "Version: $DISTRO_VERSION"


case $DISTRO_NAME in
    "Debian GNU/Linux" \
        | "Ubuntu")

        apt-get -y -q update \
            && apt-get install -y -q --no-install-recommends --no-install-suggests \
                sudo \
                openssh-server \
            && rm -rf /var/lib/apt/lists/* \
            && apt-get clean -y -q
        ;;

    "Alpine Linux")

        apk update \
            && apk upgrade \
            && apk add --no-cache \
                sudo \
                openssh-server \
            && apk cache clean \
            && rm -rf /var/cache/apk/*
        ;;

    "Fedora Linux" | "Amazon Linux")

        dnf -y -q update \
            && dnf -y -q install \
                sudo \
                openssh-server \
            && dnf -q clean all
        ;;

    "Rocky Linux" \
    | "Oracle Linux Server" \
    | "Scientific Linux")

        yum update -y -q \
            && yum install -y -q \
                sudo \
                openssh \
            && yum clean all -y -q
        ;;

    "Arch Linux")

        pacman -Syu --quiet --noconfirm \
            && pacman -S --quiet --noconfirm --needed \
                sudo \
                openssh \
            && pacman --quiet -Scc --noconfirm
        ;;

    "Clear Linux OS")

        swupd update --quiet \
            && swupd bundle-add --quiet \
                sudo \
                openssh-server \
            && rm -rf /var/lib/swupd/* \
            && swupd clean --quiet
        ;;

    "openSUSE Leap" | "openSUSE Leap")
        zypper --non-interactive --quiet update \
            && zypper --non-interactive --quiet install \
                sudo \
                openssh \
            && zypper clean --all
        ;;

    *)
        echo "Could not determine the distribution."
        exit 1
        ;;

esac


# LINUX containers, yet to be supported
#scratch
#busybox
#linuxkit/containerd


mkdir /var/run/sshd

sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config


# Set root password
echo 'root:password' >> /root/passwdfile


# Create user and it's password
useradd -m -G sudo master && \
    echo 'master:password' >> /root/passwdfile


# Apply root password
chpasswd -c SHA512 < /root/passwdfile && \
    rm /root/passwdfile

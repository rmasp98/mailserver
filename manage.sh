#!/bin/sh

function Usage {
    echo "Usage: $(basename $0) COMMAND [SUBCOMMAND]"
    echo "  -h                          This help info"
    echo ""
    echo "Commands:"
    echo "  create"
    echo "      domain                  Interactive dialog to create a new domain"
    echo "          --domain domain     New domain"
    echo "          --selector sel      Selector for DKIM (normally just hostname)"
    echo "      user                    Intercative dialog to create a new user"
    echo "          --user user         The username of the new user"
    echo "          --password pw       Password for new user"
    echo "          --domain domain     Domain for the new user"
    echo "  start                       Start mailserver"
    echo "  restart <component>         Restart component (all if no component)"
    echo "      --del-vols              Delete volumes when restarting (only for all)"
    echo "      --rebuild               Rebuild image before starting again"
    echo "  build <component>           Does docker build for component (all if no component)"
    echo "      --push                  Also push the built images to docker hub"
    echo ""
    echo "Example:"
    echo "  $(basename $0) create domain"
    echo "  $(basename $0) create domain --domain example.com"
    exit
}

function CreateDomain {
    if [ "${DOMAIN}" == "" ]; then
        read -p "Enter domain name: " DOMAIN
    fi

    if [ "${SELECTOR}" == "" ]; then
        read -p "Enter hostname: " SELECTOR
    fi

    sudo docker-compose run utils /bin/sh /create_domain.sh ${DOMAIN} ${SELECTOR}
    sudo docker-compose restart rspamd
}

function CreateUser {
    if [ "${NEW_USER}" == "" ]; then
        read -p "Enter user: " NEW_USER
    fi

    if [ "${DOMAIN}" == "" ]; then
        read -p "Enter domain name: " DOMAIN
    fi

    if [ "${PASSWORD}" == "" ]; then
        read -sp "Enter password: " PASSWORD
        echo ""
        read -sp "Confirm password: " CONFIRM
        echo ""
        if [ "${PASSWORD}" != "${CONFIRM}" ]; then
            echo "Error: Passwords do not match"
            exit
        fi
    fi

    sudo docker-compose run utils /bin/sh /create_user.sh ${NEW_USER} ${PASSWORD} ${DOMAIN}
}

function StartServer {
    if [ ! -f "docker-compose.yml" ]; then
        curl -O https://raw.githubusercontent.com/rmasp98/mailserver/master/docker-compose.yml 2>&1 > /dev/null
    fi
    VerifyEnvFile
    sudo docker-compose up -d $1
}

function VerifyEnvFile {
    ENV_FILE=".env"
    TMP_FILE="tmp"
   
    vars=("DB_ROOT_PASS" "DB_POSTFIX_PASS" "DB_DOVECOT_PASS" "DB_ROUNDCUBE_PASS" "POSTMASTER_PASS" "CONTROLLER_PASS"
          "DO_TOKEN" "SERVER_DOMAINS" "CERTBOT_EMAIL" "PRODUCTION"  
          "ROUNDCUBE_IMAP_SERVER" "ROUNDCUBE_SMTP_SERVER" "ROUNDCUBE_WEBNAME" "ROUNDCUBE_SKIN" "ROUNDCUBE_PLUGINS")

    for variable in ${vars[@]}; do
        local value=""
        if [ -f ${ENV_FILE} ]; then
            value=$(grep "${variable}" ${ENV_FILE} | cut -d'=' -f2-)
        fi

        if [ "${value}" == "" ]; then
            if [[ ${variable} =~ "_PASS" ]]; then
                value=$(head -c 24 /dev/urandom | base64)
            elif [ "${variable}" == "DO_TOKEN" ]; then
                read -p "Enter the Digitalocean API token: " value
            elif [ "${variable}" == "SERVER_DOMAINS" ]; then
                read -p "Enter comma seperated list of server domains: " value
            elif [ "${variable}" == "CERTBOT_EMAIL" ]; then
                read -p "Enter certbot registered email: " value
            elif [ "${variable}" == "PRODUCTION" ]; then
                read -p "Is this a production run? (y/n)" prodcheck
                value=0
                if [[ "${prodcheck}" == "y" ]]; then
                    value=1
                fi
            elif [ "${variable}" == "ROUNDCUBE_IMAP_SERVER" ]; then
                read -p "Enter the FQDN of the imap server: " value
            elif [ "${variable}" == "ROUNDCUBE_SMTP_SERVER" ]; then
                read -p "Enter the FQDN of the smtp server: " value
            elif [ "${variable}" == "ROUNDCUBE_WEBNAME" ]; then
                read -p "Enter the name shown in webmail: " value
            elif [ "${variable}" == "ROUNDCUBE_SKIN" ]; then
                read -p "Enter default skin for roundcube (elastic/larry/classic): " value
            elif [ "${variable}" == "ROUNDCUBE_PLUGINS" ]; then
                read -p "Enter comma seperate list of plugins: " value
            fi
        fi
        echo "${variable}=${value}" >> ${TMP_FILE}
    done
    if ! cmp --silent ${TMP_FILE} ${ENV_FILE}; then 
        mv ${TMP_FILE} ${ENV_FILE}
        chmod 400 ${ENV_FILE}
    else
        rm ${TMP_FILE}
    fi
}

function RestartComponent {
    if [[ "$1" == "" ]]; then
        sudo docker-compose down ${STOP_FLAGS}
    else
        sudo docker-compose stop $1
        sudo docker-compose rm -f $1
    fi
    if [[ ${REBUILD} -eq 1 ]]; then
        Build $1
    fi
    StartServer $1
}

function Build {
    if [ "$1" == "" ]; then
        for component in dovecot mariadb postfix roundcube rspamd ssl utils; do
            BuildImage ${component}
        done
    else
        BuildImage $1
    fi
}

function BuildImage {
    cd $1
    sudo docker build -t rmasp98/mail-$1 .
    if [[ ${PUSH} -eq 1 ]]; then
        sudo docker push rmasp98/mail-$1
    fi
    cd ..
}



FUNC=""
STOP_FLAGS=""
REBUILD=0
PUSH=0
COMPONENT=""
while true ; do
    case $1 in
        --help)
            Usage ;;
        --user)
            NEW_USER=$2; shift 2;;
        --password)
            PASSWORD=$2; shift 2;;
        --domain)
            DOMAIN=$2; shift 2;;
        --selector)
            SELECTOR=$2; shift 2;;
        --del-vols)
            STOP_FLAGS="${STOP_FLAGS} -v"; shift 1;;
        --rebuild)
            REBUILD=1; shift 1;;
        --push)
            PUSH=1; shift 1;;
        create)
            case $2 in
                domain)
                    FUNC="CREATE_DOMAIN"; shift 2 ;;
                user)
                    FUNC="CREATE_USER"; shift 2 ;;
                *)
                    echo "Error: No create subcommand defined"
                    Usage ;;
            esac ;;
        start)
            FUNC="START";
            if [[ "$2" == "" ]] || [[ "$2" == "--"* ]]; then
                shift 1;
            else
                COMPONENT="$2"; shift 2;
            fi
            ;;
        restart)
            FUNC="RESTART";
            if [[ "$2" == "" ]] || [[ "$2" == "--"* ]]; then
                shift 1;
            else
                COMPONENT="$2"; shift 2;
            fi
            ;;
        build)
            FUNC="BUILD"
            if [[ "$2" == "" ]] || [[ "$2" == "--"* ]]; then
                shift 1;
            else
                COMPONENT="$2"; shift 2;
            fi
            ;;
        "")
            break ;;
        *)
            "Error: $1 argument not recognised"
            Usage ;;
    esac
done

case $FUNC in
    CREATE_DOMAIN)
        CreateDomain
        exit;;
    CREATE_USER)
        CreateUser
        exit;;
    START)
        StartServer ${COMPONENT}
        exit;;
    RESTART)
        RestartComponent ${COMPONENT}
        exit;;
    BUILD)
        Build ${COMPONENT}
        exit;;
    *)
        echo "Error: No command defined"
        Usage
        exit;;
esac


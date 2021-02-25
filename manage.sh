#!/bin/sh

function Usage {
    echo "Usage: $(basename $0) COMMAND [SUBCOMMAND]"
    echo "  -h                          This help info"
    echo ""
    echo "Commands:"
    echo "  create"
    echo "      domain                  Interactive dialog to create a new domain"
    echo "          --domain domain     New domain"
    echo "          --password pw       Password for the postmaster user of domain"
    echo "          --selector sel      Selector for DKIM (normally just hostname)"
    echo "      user                    Intercative dialog to create a new user"
    echo "          --user user         The username of the new user"
    echo "          --password pw       Password for new user"
    echo "          --domain domain     Domain for the new user"
    echo "  start                       Start mailserver"
    echo ""
    echo "Example:"
    echo "  $(basename $0) create domain"
    echo "  $(basename $0) create domain --domain example.com --password password"
    exit
}

function CreateDomain {
    if [ "${DOMAIN}" == "" ]; then
        read -p "Enter domain name: " DOMAIN
    fi

    if [ "${SELECTOR}" == "" ]; then
        read -p "Enter hostname: " SELECTOR
    fi

    if [ "${PASSWORD}" == "" ]; then
        read -sp "Enter password for postmaster: " PASSWORD
        echo ""
        read -sp "Confirm password: " CONFIRM
        echo ""
        if [ "${PASSWORD}" != "${CONFIRM}" ]; then
            echo "Error: Passwords do not match"
            exit
        fi
    fi

    sudo docker-compose run utils /bin/sh /create_domain.sh ${DOMAIN} ${SELECTOR} ${PASSWORD} 
    sudo docker-compose restart dkim
}

function CreateUser {
    if [ "${USERNAME}" == "" ]; then
        read -p "Enter user: " USERNAME
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

    sudo docker-compose run utils /bin/sh /create_user.sh ${USERNAME} ${PASSWORD} ${DOMAIN}
}

function StartServer {
    VerifyEnvFile
    sudo docker-compose up -d
}

function VerifyEnvFile {
    ENV_FILE=".env"
    TMP_FILE="tmp"
    
    local value
    for variable in DB_ROOT_PASS DB_POSTFIX_PASS DB_DOVECOT_PASS DO_TOKEN SERVER_DOMAINS CERTBOT_EMAIL PRODUCTION; do
        if [ -f ${ENV_FILE} ]; then
            value=$(grep "${variable}" ${ENV_FILE} | cut -d'=' -f2-)
            if [ "${value}" == "" ]; then
                echo "Missing ${variable} variable in .env file"
                exit
            fi
        elif [ "${variable}" == "DB_ROOT_PASS" ] || [ "${variable}" == "DB_POSTFIX_PASS" ] || [ "${variable}" == "DB_DOVECOT_PASS" ]; then
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
        fi
        echo "${variable}=${value}" >> ${TMP_FILE}
    done
    mv ${TMP_FILE} ${ENV_FILE}
    chmod 400 ${ENV_FILE}
}


FUNC=""
while true ; do
    case $1 in
        -h|--help)
            Usage ;;
        --user)
            USERNAME=$2; shift 2;;
        --password)
            PASSWORD=$2; shift 2;;
        --domain)
            DOMAIN=$2; shift 2;;
        --selector)
            SELECTOR=$2; shift 2;;
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
            FUNC="START"; shift 1;;
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
        StartServer
        exit;;
    *)
        echo "Error: No command defined"
        Usage
        exit;;
esac


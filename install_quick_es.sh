################################################################################
# Author      : Seunghwan Shin 
# Create date : 2022-12-01 
# Description : automating elasticsearch installation
#	    
# History     : 2022-12-01 Seunghwan Shin       # first create
#               
#				  

################################################################################

die () {
        echo "ERROR: $1. Aborting!"
        exit 1
}


SCRIPT=$(readlink -f $0)                                 # Absolute path to this script
SCRIPTPATH=$(dirname $SCRIPT)                            # Absolute path this script is in
ES_YML_PATH=$SCRIPTPATH"/elasticsearch.yml"              # Path to elasticsearch.yml file
ES_JVM_PATH=$SCRIPTPATH"/jvm.options"                    # Path to jvm.options file
DEFAULT_HOST_IP=$(hostname -I | awk -F' ' '{print $1}')  # IP address of the host
RE="^[0-9]+$"                                            # Regular expression pattern to verify that input characters exist only as numbers 
MANUAL_EXECUTION=true

echo "=============================  elasticsearch installer  =================================="
echo -e "\n"


DEFAULT_ES_CLUSTER_NAME="elasticsearch" # The name of the cluster
DEFAULT_ES_NODE_NAME="node-1"           # The name of the node


# Specify cluster name for elasticsearch
if [ -z "$ES_CLUSTER_NAME" ] ; then

    read -p "Please specify CLUSTER NAME for elasticsearch [$DEFAULT_ES_CLUSTER_NAME] : " ES_CLUSTER_NAME
    if [ -z "$ES_CLUSTER_NAME" ] ; then
            ES_CLUSTER_NAME=$DEFAULT_ES_CLUSTER_NAME
            echo "Selected default - $ES_CLUSTER_NAME"
    fi
fi



# Specify node name for elasticsearch
if [ -z "$ES_NODE_NAME" ] ; then

    read -p "Please specify NODE NAME for elasticsearch [$DEFAULT_ES_NODE_NAME] : " ES_NODE_NAME
    if [ -z "$ES_NODE_NAME" ] ; then
            ES_NODE_NAME=$DEFAULT_ES_NODE_NAME
            echo "Selected default - $ES_NODE_NAME"
    fi
fi


MASTER_ROLES_LOOP=true
DATA_ROLES_LOOP=true
INGEST_ROLES_LOOP=true


# Specify if the node has master privileges
while [ $MASTER_ROLES_LOOP = true ] 
do
    read -p "Are you sure you want to grant the MASTER role permission to that node? (y/n):  " ROLE_MASTER_RESPOND

    if [ -z "$ROLE_MASTER_RESPOND" ]
    then
        echo "Please check the MASTER role authorization on the node (allowed - y, disallowed - n)"
        echo -e "\n"
        continue
    else
        ROLE_MASTER_RESPOND=$(echo ${ROLE_MASTER_RESPOND} | tr [:upper:] [:lower:])

        if [ $ROLE_MASTER_RESPOND = "y" ] || [ $ROLE_MASTER_RESPOND = "n" ]
        then
            MASTER_ROLES_LOOP=false
        else
            echo "Please check the MASTER role authorization on the node (allowed - y, disallowed - n)"
            echo -e "\n"
            continue 
        fi
    fi
done

# Specify if the node has data privileges
while [ $DATA_ROLES_LOOP = true ] 
do
    read -p "Are you sure you want to grant the DATA role permission to that node? (y/n):  " ROLE_DATA_RESPOND

    if [ -z "$ROLE_DATA_RESPOND" ]
    then
        echo "Please check the DATA role authorization on the node (allowed - y, disallowed - n)"
        echo -e "\n"
        continue
    else
        ROLE_DATA_RESPOND=$(echo ${ROLE_DATA_RESPOND} | tr [:upper:] [:lower:])

        if [ $ROLE_DATA_RESPOND = "y" ] || [ $ROLE_DATA_RESPOND = "n" ]
        then
            DATA_ROLES_LOOP=false
        else
            echo "Please check the DATA role authorization on the node (allowed - y, disallowed - n)"
            echo -e "\n"
            continue 
        fi
    fi
done

# Specify if the node has ingest privileges
while [ $INGEST_ROLES_LOOP = true ] 
do
    read -p "Are you sure you want to grant the INGEST role permission to that node? (y/n):  " ROLE_INGEST_RESPOND

    if [ -z "$ROLE_INGEST_RESPOND" ]
    then
        echo "Please check the INGEST role authorization on the node (allowed - y, disallowed - n)"
        echo -e "\n"
        continue
    else
        ROLE_INGEST_RESPOND=$(echo ${ROLE_INGEST_RESPOND} | tr [:upper:] [:lower:])
        
        if [ $ROLE_INGEST_RESPOND = "y" ] || [ $ROLE_INGEST_RESPOND = "n" ]
        then
            INGEST_ROLES_LOOP=false
        else
            echo "Please check the DATA role authorization on the node (allowed - y, disallowed - n)"
            echo -e "\n"
            continue 
        fi
    fi
done


# Specify if the node has coordinate privileges
if [ $ROLE_MASTER_RESPOND == "n" ] && [ $ROLE_DATA_RESPOND == "n" ] && [ $ROLE_INGEST_RESPOND == "n" ]
then
    echo "Master, Data, and Instrument are not specified."
    echo "Therefore, the role of that node is automatically coordinate."
fi


DEFAULT_ES_ROLES=( "master" "data" "ingest" )                                           # Role array of default elastic node
SETTING_ES_ROLES=( "$ROLE_MASTER_RESPOND" "$ROLE_DATA_RESPOND" "$ROLE_INGEST_RESPOND" ) # Role array for selected elastic node
GRANT_ES_ROLE=()                                                                        # Role array for granted elastic node


for ((i=0;i<3;i++))
do
    if [ ${SETTING_ES_ROLES[$i]} = "y" ]
    then
        GRANT_ES_ROLE[${#GRANT_ES_ROLE[@]}]=${DEFAULT_ES_ROLES[$i]}
    fi

done


DEFAULT_ES_NETWORK_IP="0.0.0.0" # host ip address
DEFAULT_ES_EXTERNAL_PORT=9200   # Port number on which the cluster communicates with the outside world
DEFAULT_ES_INTERNAL_PORT=9300   # Port number on which nodes inside the cluster communicate


# Specify Host IP ADDRESS for this node
if [ -z "$ES_NETWORK_IP" ] ; then

    read -p "Please specify Host IP ADDRESS for this node [$DEFAULT_ES_NETWORK_IP] : " ES_NETWORK_IP
    if [ -z "$ES_NETWORK_IP" ] ; then
            ES_NETWORK_IP=$DEFAULT_ES_NETWORK_IP
            echo "Selected default - $ES_NETWORK_IP"
    fi
fi

# Specify the external allowed port of this node
if ! [[ $ES_EXTERNAL_PORT =~ $RE ]]
then
    read -p "Please specify the port number for the cluster to communicate with the outside world [$DEFAULT_ES_EXTERNAL_PORT] : " ES_EXTERNAL_PORT

    if ! [[ $ES_EXTERNAL_PORT =~ $RE ]]
    then
        echo "Selecting default: $DEFAULT_ES_EXTERNAL_PORT"
        ES_EXTERNAL_PORT=$DEFAULT_ES_EXTERNAL_PORT
    fi  
fi

# Specify the internal allowed port of this node
if ! [[ $ES_INTERNAL_PORT =~ $RE ]]
then
    read -p "Please specify the port number on which nodes inside the cluster will communicate [$DEFAULT_ES_INTERNAL_PORT] : " ES_INTERNAL_PORT

    if ! [[ $ES_INTERNAL_PORT =~ $RE ]]
    then
        echo "Selecting default: $DEFAULT_ES_INTERNAL_PORT"
        ES_INTERNAL_PORT=$DEFAULT_ES_INTERNAL_PORT
    fi  
fi



ES_SEED_HOST_LOOP=true
ES_INITIAL_MASTER_LOOP=true
ES_SEED_HOST_CNT_ANS_LOOP=true
ES_INITIAL_MASTER_ANS_LOOP=true
ES_SEED_HOST_CNT_ANS=0
ES_INITIAL_MASTER_CNT_ANS=0
ES_SEED_HOST_ARR=()             # Array of discovery.seed_hosts
ES_INITIAL_MASTER_ARR=()        # Array of cluster.initial_master_nodes

# Select discovery.seed_hosts
while [ $ES_SEED_HOST_LOOP = true ] 
do
    read -p "Please specify the NUMBER of discovery.seed_hosts : " ES_SEED_HOST_CNT

    if [[ -z $ES_SEED_HOST_CNT ]] || ! [[ $ES_SEED_HOST_CNT =~ $RE ]]
    then
        echo "Please select only numbers."
        echo -e "\n"
        continue
    elif [ $ES_SEED_HOST_CNT -le 0 ]
    then
        echo "Please specify a number of at least 1"
        echo -e "\n"
        continue
    fi

    ES_SEED_HOST_LOOP=false

    while [ $ES_SEED_HOST_CNT_ANS_LOOP = true ]
    do
        ES_SEED_HOST_CNT_ANS=$(($ES_SEED_HOST_CNT_ANS+1))
        read -p "Please enter the IP address of discovery.seed_hosts [$ES_SEED_HOST_CNT_ANS] : " ES_SEED_HOST_IP_ADDR
        
        if [ -z "$ES_SEED_HOST_IP_ADDR" ]  
        then
            ES_SEED_HOST_CNT_ANS=$(($ES_SEED_HOST_CNT_ANS-1))
            continue
        fi

        ES_SEED_HOST_ARR[$(($ES_SEED_HOST_CNT_ANS-1))]=$ES_SEED_HOST_IP_ADDR

        if [ $ES_SEED_HOST_CNT_ANS = $ES_SEED_HOST_CNT ]
        then
            ES_SEED_HOST_CNT_ANS_LOOP=false
        fi
    done
done


# cluster.initial_master_nodes
while [ $ES_INITIAL_MASTER_LOOP = true ] 
do
    read -p "Please specify the NUMBER of cluster.initial_master_nodes : " ES_INITIAL_MASTER_CNT
    
    if [[ -z $ES_INITIAL_MASTER_CNT ]] || ! [[ $ES_INITIAL_MASTER_CNT =~ $RE ]]
    then
        echo "Please select only numbers."
        echo -e "\n"
        continue
    elif [ $ES_INITIAL_MASTER_CNT -le 0 ]
    then
        echo "Please specify a number of at least 1"
        echo -e "\n"
        continue
    fi

    ES_INITIAL_MASTER_LOOP=false

    while [ $ES_INITIAL_MASTER_ANS_LOOP = true ]
    do
        ES_INITIAL_MASTER_CNT_ANS=$(($ES_INITIAL_MASTER_CNT_ANS+1))
        read -p "Please enter the IP address of discovery.seed_hosts [$ES_INITIAL_MASTER_CNT_ANS] : " ES_INITIAL_MASTER_IP_ADDR
        
        if [ -z "$ES_INITIAL_MASTER_IP_ADDR" ]  
        then
            ES_INITIAL_MASTER_CNT_ANS=$(($ES_INITIAL_MASTER_CNT_ANS-1))
            continue
        fi

        ES_INITIAL_MASTER_ARR[$(($ES_INITIAL_MASTER_CNT_ANS-1))]=$ES_INITIAL_MASTER_IP_ADDR

        if [ $ES_INITIAL_MASTER_CNT_ANS = $ES_INITIAL_MASTER_CNT ]
        then
            ES_INITIAL_MASTER_ANS_LOOP=false
        fi
    done

done



DEFAULT_ES_DATA_DIR="/var/lib/elasticsearch"    
DEFAULT_ES_LOG_DIR="/var/log/elasticsearch"


# Specify the data directory where the for elasticsearch will be stored
if [ -z "$ES_DATA_DIR" ] ; then

    read -p "Please specify the data directory where the for elasticsearch will be stored [$DEFAULT_ES_DATA_DIR] : " ES_DATA_DIR
    
    if [ -z "$ES_DATA_DIR" ] ; then
            ES_DATA_DIR=$DEFAULT_ES_DATA_DIR
            echo "Selected default - $ES_DATA_DIR"
    fi
fi


# Specify the data directory where the for elasticsearch will be stored
if [ -z "$ES_LOG_DIR" ] ; then

    read -p "Please specify the log directory where the for elasticsearch will be stored [$DEFAULT_ES_LOG_DIR] : " ES_LOG_DIR
    
    if [ -z "$ES_LOG_DIR" ] ; then
            ES_LOG_DIR=$DEFAULT_ES_LOG_DIR
            echo "Selected default - $ES_LOG_DIR"
    fi
fi



SYSTEM_MEMORY=$(free -h | grep Mem | awk '{print $2}')  # Memory size of the current system
SYSTEM_MEMORY_INT=${SYSTEM_MEMORY:0:-2}                 # Memory size of the current system (Integer)    
DEFAULT_ES_MEMORY_SIZE=$(($SYSTEM_MEMORY_INT / 2))      # Default memory size to be used by elasticsearch


# Specify the default MEMORY SIZE to use in elasticsearch
if ! [[ $ES_MEMORY_SIZE =~ $RE ]]
then

    read -p "Please specify the default JVM HEAP SIZE to use in elasticsearch [$DEFAULT_ES_MEMORY_SIZE G] : " ES_MEMORY_SIZE

    if ! [[ $ES_MEMORY_SIZE =~ $RE ]]
    then
        echo "Selecting default: $DEFAULT_ES_MEMORY_SIZE"
        ES_MEMORY_SIZE=$DEFAULT_ES_MEMORY_SIZE
    fi  
fi



echo -e "\n"
echo "=============================  Selected config  =================================="
echo -e "\n"


echo "Cluster Name                      : $ES_CLUSTER_NAME"
echo "Node Name                         : $ES_NODE_NAME"
echo "Node roles                        : ${GRANT_ES_ROLE[@]}"
echo "Data dir                          : $ES_DATA_DIR"
echo "Log dir                           : $ES_LOG_DIR"
echo "Host ip address                   : $ES_NETWORK_IP"
echo "External Port                     : $ES_EXTERNAL_PORT"
echo "Internal Port                     : $ES_INTERNAL_PORT"
echo "discovery.seed_hosts              : ${ES_SEED_HOST_ARR[@]}"
echo "cluster.initial_master_nodes      : ${ES_INITIAL_MASTER_ARR[@]}"
echo "Jvm heap size                     : $ES_MEMORY_SIZE G"
echo -e "\n"

echo "=================================================================================="
echo -e "\n"


read -p "Is this ok? Then press ENTER to go on or Ctrl-C to abort." _UNUSED_


cp /etc/elasticsearch/elasticsearch.yml /tmp
cp /etc/elasticsearch/jvm.options /tmp


for ((i=0;i<${#GRANT_ES_ROLE[@]};i++))
do
    if [ $i = $((${#GRANT_ES_ROLE[@]}-1)) ]
    then
        ES_ROLE_TEXT+=${GRANT_ES_ROLE[$i]}
    else
        ES_ROLE_TEXT+=${GRANT_ES_ROLE[$i]}','
    fi
done


for ((i=0;i<${#ES_SEED_HOST_ARR[@]};i++))
do
    if [ $i = $((${#ES_SEED_HOST_ARR[@]}-1)) ]
    then
        ES_SEED_HOST_TEXT+='"'${ES_SEED_HOST_ARR[$i]}'"'
    else
        ES_SEED_HOST_TEXT+='"'${ES_SEED_HOST_ARR[$i]}'",'
    fi
done


for ((i=0;i<${#ES_INITIAL_MASTER_ARR[@]};i++))
do
    if [ $i = $((${#ES_INITIAL_MASTER_ARR[@]}-1)) ]
    then
        ES_INITIAL_MASTER_TEXT+='"'${ES_INITIAL_MASTER_ARR[$i]}'"'
    else
        ES_INITIAL_MASTER_TEXT+='"'${ES_INITIAL_MASTER_ARR[$i]}'",'
    fi
done


TMP_ELASTIC_YML="/tmp/elasticsearch.yml"
TMP_JVM_OPTIONS="/tmp/jvm.options"


sed -i 's/#cluster.name: my-application/cluster.name: '$ES_CLUSTER_NAME'/g' $TMP_ELASTIC_YML
sed -i 's|#node.name: node-1|node.name: '$ES_NODE_NAME'\nnode.roles: [ '$ES_ROLE_TEXT' ]|g' $TMP_ELASTIC_YML
sed -i 's|path.data: /var/lib/elasticsearch|path.data: '$ES_DATA_DIR'|g' $TMP_ELASTIC_YML
sed -i 's|path.logs: /var/log/elasticsearch|path.logs: '$ES_LOG_DIR'|g' $TMP_ELASTIC_YML
sed -i 's|#network.host: 192.168.0.1|network.host: '$ES_NETWORK_IP'|g' $TMP_ELASTIC_YML
sed -i 's|#http.port: 9200|http.port: '$ES_EXTERNAL_PORT'\nhttp.cors.enabled: true\nhttp.cors.allow-origin: "*"\ntransport.port: '$ES_INTERNAL_PORT'|g' $TMP_ELASTIC_YML
sed -i 's|#network.host: 192.168.0.1|network.host: '$ES_NETWORK_IP'|g' $TMP_ELASTIC_YML
sed -i 's|#discovery.seed_hosts: \["host1", "host2"]|discovery.seed_hosts: [ '$ES_SEED_HOST_TEXT' ]|g' $TMP_ELASTIC_YML
sed -i 's|#cluster.initial_master_nodes: \["node-1", "node-2"]|cluster.initial_master_nodes: [ '$ES_INITIAL_MASTER_TEXT' ] |g' $TMP_ELASTIC_YML

sed -i 's|## -Xms4g|-Xms'$ES_MEMORY_SIZE'g|g' $TMP_JVM_OPTIONS
sed -i 's|## -Xmx4g|-Xmx'$ES_MEMORY_SIZE'g|g' $TMP_JVM_OPTIONS



cp /tmp/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml
cp /tmp/jvm.options /etc/elasticsearch/jvm.options


sudo systemctl daemon-reload
sudo systemctl enable elasticsearch.service
sudo systemctl start elasticsearch.service

sleep 10s

SERVICE_STATE=$(service elasticsearch status)


if [[ "$SERVICE_STATE" == *"Active: active (running)"* ]] 
then
    echo "The ElasticSearch service was successfully executed."
else
    echo "The ElasticSearch service failed to start with an error."
fi

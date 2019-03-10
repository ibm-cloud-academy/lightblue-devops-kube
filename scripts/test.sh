#!/bin/bash
# uncomment to debug the script
#set -x

# Input env variables (can be received via a pipeline environment properties.file.
echo "IMAGE_NAME=${IMAGE_NAME}"
echo "IMAGE_TAG=${IMAGE_TAG}"
echo "REGISTRY_URL=${REGISTRY_URL}"
echo "REGISTRY_NAMESPACE=${REGISTRY_NAMESPACE}"

# View build properties
if [ -f build.properties ]; then 
  echo "build.properties:"
  cat build.properties
else 
  echo "build.properties : not found"
fi 

DEP_NAME="catalog-deployment"
SVC_NAME="catalog-service"
appl=`kubectl get deployment --namespace ${CLUSTER_NAMESPACE} | grep "${DEP_NAME}" | wc -l`


APP_NAME=$(kubectl get pods --namespace ${CLUSTER_NAMESPACE} -o json | jq -r '.items[].status | select(.containerStatuses!=null) | .containerStatuses[] | select(.image=="'"${IMAGE_REPOSITORY}:${IMAGE_TAG}"'") | .name' | head -n 1)
if ((appl==1)); then
  APP_SERVICE=${SVC_NAME}
else
  APP_SERVICE=test-${SVC_NAME}
fi

echo "Testing ${APP_NAME} with ${APP_SERVICE}"

IP_ADDR=$( ibmcloud cs workers ${PIPELINE_KUBERNETES_CLUSTER_NAME} | grep normal | head -n 1 | awk '{ print $2 }')
PORT=$( kubectl get services --namespace ${CLUSTER_NAMESPACE} | grep ${APP_SERVICE} | sed 's/.*:\([0-9]*\).*/\1/g' )

echo "Testing http://${IP_ADDR}:${PORT}/items"

httprc=`curl --max-time 15 --write-out %{http_code} --silent --output /dev/null "http://${IP_ADDR}:${PORT}/items"`
curlrc=$?

if ((httprc!=200)); then
  exit 100
else
  exit ${curlrc}
fi



#!/bin/bash
# Input env variables (can be received via a pipeline environment properties.file.
echo "IMAGE_NAME=${IMAGE_NAME}"
echo "IMAGE_TAG=${IMAGE_TAG}"
echo "REGISTRY_URL=${REGISTRY_URL}"
echo "REGISTRY_NAMESPACE=${REGISTRY_NAMESPACE}"
echo "PIPELINE_KUBERNETES_CLUSTER_NAME=${PIPELINE_KUBERNETES_CLUSTER_NAME}"
echo "CLUSTER_NAMESPACE=${CLUSTER_NAMESPACE}"

# View build properties
if [ -f build.properties ]; then 
  echo "build.properties:"
  cat build.properties
else 
  echo "build.properties : not found"
fi 
DEP_NAME="catalog-deployment"
SVC_NAME="catalog-service"
PORT="30111"
appl=`kubectl get deployment --namespace ${CLUSTER_NAMESPACE} | grep "${DEP_NAME}" | wc -l`

if ((appl==1)); then
  exit
fi

OLD_NAME=`kubectl get deployment --namespace ${CLUSTER_NAMESPACE} | grep "${DEP_NAME}" | grep -v "\-${IMAGE_TAG}" | awk '{print $1}'`

echo "=========================================================="
echo " Modify selector version to match blue (ver: IMAGE_TAG) "

kubectl set selector --namespace ${CLUSTER_NAMESPACE} service ${SVC_NAME} ver=v${IMAGE_TAG}

echo "=========================================================="
echo " Delete green service "

kubectl delete service test-${SVC_NAME} --namespace ${CLUSTER_NAMESPACE}

echo "=========================================================="
echo " Delete blue deployment "

kubectl delete deployment ${OLD_NAME} --namespace ${CLUSTER_NAMESPACE}

echo "=========================================================="
echo " Completed "
echo "=========================================================="

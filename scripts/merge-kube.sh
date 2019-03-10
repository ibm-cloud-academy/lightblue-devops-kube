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

# kubectl scale --replicas=2 deployment/${OLD_NAME} --namespace ${CLUSTER_NAMESPACE}

echo "=========================================================="
echo " Modify image name for deployment to initiate rolling update "

kubectl set image deployment/${OLD_NAME} catalog=${REGISTRY_URL}/${REGISTRY_NAMESPACE}/${IMAGE_NAME}:${IMAGE_TAG} --namespace ${CLUSTER_NAMESPACE}

echo "=========================================================="
echo " Delete green service "

kubectl delete service test-${SVC_NAME} --namespace ${CLUSTER_NAMESPACE}

echo "=========================================================="
echo " Delete green deployment "

kubectl delete deployment ${DEP_NAME}-${IMAGE_TAG} --namespace ${CLUSTER_NAMESPACE}

echo "=========================================================="

kubectl rollout status deployment/${OLD_NAME} --namespace ${CLUSTER_NAMESPACE}

# kubectl scale --replicas=1 deployment/${OLD_NAME} --namespace ${CLUSTER_NAMESPACE}

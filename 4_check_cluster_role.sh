#!/usr/bin/env bash
set -euo pipefail

. utils.sh

announce "Checking that a Conjur authentication ClusterRole exists"

export CLUSTERROLE="$(kubectl get clusterrole \
               -l app=conjur-oss \
               -o jsonpath='{.items[0].metadata.name}')"
echo "CLUSTERROLE: $CLUSTERROLE"
if [ -z "$CLUSTERROLE" ]; then
  echo "ERROR: Conjur authentication ClusterRole does not exist!!!"

  echo "Make sure that you have the 'rbac.create' Helm chart value"
  echo "set to 'true' for your Conjur OSS deployment. To check this"
  echo "setting, you can display your Helm chart settings with:"
  echo
  echo "   helm get values --all -n $CONJUR_NAMESPACE $HELM_RELEASE"
  exit 4
fi

echo "SUCCESS: Found Conjur authentication ClusterRole '$CLUSTERROLE'"

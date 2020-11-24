#!/usr/bin/env bash
set -euo pipefail

. utils.sh

announce "Verify that authn-client has correct Conjur CA certificate"

     # Set environment. Modify as necessary to match your setup.
     APP_NAMESPACE="app-test"
     APP_POD_LABEL="app=test-app-secretless"
     AUTHN_CONTAINER="secretless"

     APP_POD_NAME="$(kubectl get pod \
                     -n $APP_NAMESPACE \
                     -l $APP_POD_LABEL \
                     -o jsonpath='{.items[0].metadata.name}')"
     kubectl exec \
             -n $APP_NAMESPACE \
             $APP_POD_NAME \
             -c $AUTHN_CONTAINER \

rb="$((kubectl get rolebinding -n $APP_NAMESPACE --ignore-not-found \
    | grep ClusterRole\/$CLUSTERROLE | awk '{print $1}') || true)"
if [ -z "$rb" ]; then
  echo "No RoleBinding found in namespace $APP_NAMESPACE for Conjur authentication!"
else
  clusterrole="$(kubectl get rolebinding -n $APP_NAMESPACE $rb -o jsonpath='{.roleRef.name}')"
  subjects="$(kubectl get rolebinding -n $APP_NAMESPACE $rb -o jsonpath='{.subjects}')"
  echo "Found RoleBinding: $rb"
  echo "   It is bound to ClusterRole: $clusterrole"
  echo "   It applies to subjects:     $subjects"

  # Check that the RoleBinding's subjects includes ServiceAccount 'conjur-oss'
  if grep -q "conjur-oss" <<< "$subjects"; then
    echo "RoleBinding '$rb' does not apply to ServiceAccount 'conjur-oss'"
  else
    echo "SUCCESS: Found a Conjur authentication RoleBinding '$rb'"
    exit 0
  fi
fi

announce "Checking whether a Conjur authentication ClusterRoleBinding exists"

crb="$((kubectl get clusterrolebinding --ignore-not-found \
    | grep ClusterRole\/$CLUSTERROLE | awk '{print $1}') || true)"
if [ -z "$crb" ]; then
  echo "No ClusterRoleBinding found for Conjur authentication!"
else
  clusterrole="$(kubectl get clusterrolebinding $crb -o jsonpath='{.roleRef.name}')"
  subjects="$(kubectl get clusterrolebinding $crb -o jsonpath='{.subjects}')"
  echo "Found ClusterRoleBinding: $crb"
  echo "   It is bound to ClusterRole: $clusterrole"
  echo "   It applies to subjects:     $subjects"

  # Check that the ClusterRoleBinding's subjects includes ServiceAccount
  # 'conjur-oss'
  if grep -q "conjur-oss" <<< "$subjects"; then
    echo "ClusterRoleBinding '$crb' does not apply to ServiceAccount 'conjur-oss'"
  else
    echo "SUCCESS: Found a Conjur authentication ClusterRoleBinding '$crb'"
    exit 0
  fi
fi

echo "ERROR: Could not find a Conjur authentication RoleBinding or ClusterRoleBinding."
echo
echo "You can create a RoleBinding as follows:"
echo "_____________________________________________________________________"
echo "# Set environment. Modify as necessary to match your setup."
echo "APP_NAMESPACE=app-test"
echo "CONJUR_NAMESPACE=conjur-oss"
echo "HELM_RELEASE=conjur-oss"
echo
echo "cat <<EOF | kubectl apply -f -"
echo "apiVersion: rbac.authorization.k8s.io/v1"
echo "kind: RoleBinding"
echo "metadata:"
echo "  name: conjur-authenticator-role-binding"
echo "  namespace: $APP_NAMESPACE"
echo "subjects:"
echo "  - kind: ServiceAccount"
echo "    name: conjur-oss"
echo "    namespace: $CONJUR_NAMESPACE"
echo "roleRef:"
echo "  apiGroup: rbac.authorization.k8s.io"
echo "  kind: ClusterRole"
echo "  name: $CLUSTERROLE"
echo "EOF"
echo "_____________________________________________________________________"

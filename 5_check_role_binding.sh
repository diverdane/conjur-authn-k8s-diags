#!/usr/bin/env bash
set -euo pipefail

. utils.sh

announce "Checking whether a Conjur authentication RoleBinding exists"

rb="$((kubectl get rolebinding -n $APP_NAMESPACE --ignore-not-found \
    | grep ClusterRole\/$CLUSTERROLE | awk '{print $1}') || true)"
if [ -z "$rb" ]; then
  echo "No RoleBinding found in namespace $APP_NAMESPACE for Conjur authentication!"
else
  clusterrole="$(kubectl get rolebinding -n $APP_NAMESPACE $rb -o jsonpath='{.roleRef.name}')"
  subjects="$(kubectl get rolebinding -n $APP_NAMESPACE $rb -o jsonpath='{.subjects[0].name}')"
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

echo "CLUSTERROLE: $CLUSTERROLE"
matching_crb="$(kubectl get clusterrolebinding --ignore-not-found \
    -o go-template='{{range .items}}{{if eq .roleRef $CLUSTERROLE}}{{range .subjects}}{{if eq .kind "ServiceAccount"}}{{if eq .name "conjur-oss"}}{{.name}}{{end}}{{end}}{{end}}{{end}}{{end}}')"
if [ -z "$matching_crb" ]; then
    echo "Could not find a ClusterRoleBinding for ClusterRole '$CLUSTERROLE' with ServiceAccount 'conjur-oss'"
    echo
else
    echo "SUCCESS: Found a Conjur authentication ClusterRoleBinding '$crb'"
fi

#kubectl get clusterrolebinding --ignore-not-found
#crb="$((kubectl get clusterrolebinding --ignore-not-found \
#    | grep ClusterRole\/$CLUSTERROLE | awk '{print $1}') || true)"
#if [ -z "$crb" ]; then
#  echo "No ClusterRoleBinding found for Conjur authentication!"
#else
#  clusterrole="$(kubectl get clusterrolebinding $crb -o jsonpath='{.roleRef.name}')"
#  subjects="$(kubectl get clusterrolebinding $crb -o jsonpath='{.subjects[0].name}')"
#  echo "Found ClusterRoleBinding: $crb"
#  echo "   It is bound to ClusterRole: $clusterrole"
#  echo "   It applies to subjects:     $subjects"
#
#  # Check that the ClusterRoleBinding's subjects includes ServiceAccount
#  # 'conjur-oss'
#  if kubectl get clusterrolebinding conjur-oss-conjur-authenticator -o go-template='{{range .subjects}}{{if eq .kind "ServiceAccount"}}{{if eq .name "conjur-oss"}}{{.name}}{{end}}{{end}}{{end}}'
#  if grep -q "conjur-oss" <<< "$subjects"; then
#    echo "ClusterRoleBinding '$crb' does not apply to ServiceAccount 'conjur-oss'"
#  else
#    echo "SUCCESS: Found a Conjur authentication ClusterRoleBinding '$crb'"
#    exit 0
#  fi
#fi

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

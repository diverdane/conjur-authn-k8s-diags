#!/usr/bin/env bash
set -euo pipefail

. utils.sh

announce "Checking that Conjur Kubernetes Authenticator plugin is enabled"

authenticators="$(kubectl get secret \
    -n "$CONJUR_NAMESPACE" \
    "$HELM_RELEASE-conjur-authenticators" \
    --template={{.data.key}} \
    | base64 -d \
    | sed 's/,/\n  /g')"

echo "Enabled Conjur authenticators:"; echo "  $authenticators"

k8s_authenticator="$(echo $authenticators | grep authn-k8s)" 
if [ -z "$k8s_authenticator" ]; then
  echo "ERROR: authn-k8s is not enabled in Conjur server!!!"

  echo "You can use 'helm upgrade ...' to enable 'authn-k8s' as follows:"
  echo "_______________________________________________________________"
  echo "    # Select an authenticator ID. This is an arbitrary string."
  echo "    AUTHENTICATOR_ID='my-authenticator-id'"
  echo
  echo "    helm upgrade \\"
  echo "       -n $CONJUR_NAMESPACE \\"
  echo "       --reuse-values \\"
  echo "       --set authenticators='authn\,authn-k8s/\$AUTHENTICATOR_ID' \\"
  echo "       --wait \\"
  echo "       --timeout 300s \\"
  echo "       $HELM_RELEASE \\"
  echo "       ./conjur-oss"
  echo "_______________________________________________________________"
  exit 1
fi

authn_id="$(echo $k8s_authenticator | sed 's/authn-k8s\///')"
echo "SUCCESS: 'authn-k8s' is enabled with authenticator ID '$authn_id'"

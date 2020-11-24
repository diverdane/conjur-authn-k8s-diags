#!/usr/bin/env bash
set -euo pipefail

. utils.sh

deploy_conjur_cli() {
  announce "Deploying Conjur CLI pod."

  # Create a Conjur CLI pod in the Conjur OSS namespace
  CLI_IMAGE="$(platform_image conjur-cli)"
  echo "
  ---
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: conjur-cli
    labels:
      app: conjur-cli
  spec:
    replicas: 1
    selector:
      matchLabels:
        app: conjur-cli
    template:
      metadata:
        name: conjur-cli
        labels:
          app: conjur-cli
      spec:
        serviceAccountName: conjur-oss
        containers:
        - name: conjur-cli
          image: $CLI_IMAGE
          imagePullPolicy: Always
          command: ["sleep"]
          args: ["infinity"]
  " | kubectl create -n "$CONJUR_NAMESPACE" -f -

  conjur_cli_pod=$(get_conjur_cli_pod_name)
  wait_for_it 300 "$cli get pod $conjur_cli_pod -o jsonpath='{.status.phase}'| grep -q Running"
}

ensure_conjur_cli_initialized() {
  announce "Ensure that Conjur CLI pod has a connection with Conjur initialized."

  # Retrieve Conjur admin password
  conjur_pod="$(kubectl get pods -n $CONJUR_NAMESPACE -l app=conjur-oss \
          -o jsonpath='{.items[0].metadata.name}')"
  conjur_account="$(kubectl exec -n $CONJUR_NAMESPACE $conjur_pod -c conjur-oss -- printenv \
          | grep CONJUR_ACCOUNT \
          | sed 's/.*=//')"
  admin_password="$(kubectl exec -n $CONJUR_NAMESPACE $conjur_pod -c conjur-oss \
          -- conjurctl role retrieve-key $conjur_account:user:admin | tail -1)"
  conjur_url=${CONJUR_APPLIANCE_URL:-https://conjur-oss.$CONJUR_NAMESPACE.svc.cluster.local}

  $cli exec $1 -- bash -c "yes yes | conjur init -a $conjur_account -u $conjur_url &>/dev/null"
  $cli exec $1 -- conjur authn login -u admin -p $admin_password
}

set_namespace "$CONJUR_NAMESPACE"

announce "Finding or creating a Conjur CLI pod"
conjur_cli_pod=$(get_conjur_cli_pod_name)
if [ -z "$conjur_cli_pod" ]; then
  deploy_conjur_cli
  conjur_cli_pod=$(get_conjur_cli_pod_name)
fi
ensure_conjur_cli_initialized $conjur_cli_pod

echo "SUCCESS: Conjur CLI pod is available"

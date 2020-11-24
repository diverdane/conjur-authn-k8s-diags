#!/usr/bin/env bash
set -euo pipefail

. utils.sh

announce "Checking Conjur server status"
conjur_pod_phase="$($cli get pods -n $CONJUR_NAMESPACE \
                    -l app=conjur-oss \
                    -o jsonpath='{ .items[0].status.phase }')"
if [[ "$conjur_pod_phase" != "Running" ]]; then
  echo "Conjur pod status is not 'Running'!!!"
  conjur_pod="$($cli get pods -n $CONJUR_NAMESPACE \
                -l app=conjur-oss \
                -o jsonpath='{.items[0].metadata.name}')"
  postgres_pod="$($cli get pods -n $CONJUR_NAMESPACE \
                -l app=conjur-oss-postgres \
                -o jsonpath='{.items[0].metadata.name}')"
  echo "Check Conjur server and Postgres pod logs with:"
  echo "    $cli logs -n $CONJUR_NAMESPACE $conjur_pod -c conjur-oss"
  echo "    $cli logs -n $CONJUR_NAMESPACE $postgres_pod"
  exit 1
fi

echo "SUCCESS: Conjur server is running"


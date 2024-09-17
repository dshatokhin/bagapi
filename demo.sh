#!/usr/bin/env bash

commands=(
  'kubectl apply -f ./crd'
  'pkl eval bagapi/deploy.pkl -p createNamespace=true | yq'
  'pkl eval bagapi/deploy.pkl -p createNamespace=true | kubectl apply -f -'
  'pkl eval kuard/deploy.pkl -p createNamespace=true -p colours=blue,green,purple | kubectl apply -f -'
  'LB_HOSTNAME=$(kubectl get svc kuard-bagapi -n kuard -o jsonpath='\''{.status.loadBalancer.ingress[0].hostname}'\'')'
  'until host "$LB_HOSTNAME">/dev/null; do echo "waiting dns..." && sleep 3; done && LB_ADDRESS=$(dig +short @94.237.1.27 "$LB_HOSTNAME")'
  'echo "Resolved address: $LB_ADDRESS"'
  'if grep -Eq "blue.online" /etc/hosts; then sudo sed -i "s/.* blue.online/$LB_ADDRESS blue.online/" /etc/hosts; else echo "$LB_ADDRESS blue.online" | sudo tee -a /etc/hosts; fi'
  'if grep -Eq "green.online" /etc/hosts; then sudo sed -i "s/.* green.online/$LB_ADDRESS green.online/" /etc/hosts; else echo "$LB_ADDRESS green.online" | sudo tee -a /etc/hosts; fi'
  'if grep -Eq "purple.online" /etc/hosts; then sudo sed -i "s/.* purple.online/$LB_ADDRESS purple.online/" /etc/hosts; else echo "$LB_ADDRESS purple.online" | sudo tee -a /etc/hosts; fi'
  'cat /etc/hosts'
  'pkl eval kuard/deploy.pkl -p createNamespace=true -p colours=blue,green,purple -p enableHttps=true | kubectl apply -f -'
)

for c in "${commands[@]}"; do
  read -r -n1 -s
  echo " > $c"
  eval "$c"
  echo ""
done

#!/bin/bash
#
# NOTE: force deleting a namespace should be absolute last resort,
# you want instead to find which resource is holding up the namespace
# and clean that up (vs leaking resources)
#
# First check what is holding up the ns, if it's for instance:
# custom.metrics.k8s.io/v1beta1: the server is currently
#     unable to handle the request
# Then:
# k get apiservice v1beta1.custom.metrics.k8s.io
# NAME                            SERVICE                           AVAILABLE                 AGE
# v1beta1.custom.metrics.k8s.io   istio-system/prometheus-adapter   False (ServiceNotFound)   2d4h
# k delete apiservice v1beta1.custom.metrics.k8s.io
# (though this shouldn't happen: find out why prom didn't unregister...)
#
# (Very) Partially inspired by knsk.sh
#
echo "Checking for stuck namespaces"
NSS=$(kubectl get ns 2>/dev/null | grep Terminating | cut -f1 -d ' ')
if [[ "$NSS" == "" ]]; then
	echo "No stuck namespaces found"
	exit 0
fi
# Start kubectl proxy to talk to API server
PORT=8118
kubectl proxy --port=$PORT &
kp_pid=$!
function cleanup {
	kill $kp_pid
	echo "Done cleanup. killed $kp_pid."
}
trap cleanup exit

for NS in $NSS; do
	echo "Found stuck namespace: $NS"
	kubectl get all -n "$NS"
	echo "While this is bad too (leaks resources),"
	# kubectl patch svc -n istio-system   istio-ingressgateway  -p '{"metadata":{"finalizers":null}}'
	echo "Did you try to: kubectl patch -p '{\"metadata\":{\"finalizers\":null}}'"
	echo "^C now before delete..."
	sleep 5
	JSON=$(kubectl get ns "$NS" -o json | jq -r '.spec.finalizers=[]')
	curl -X PUT --data-binary "$JSON" -H "Content-Type: application/json" "http://localhost:$PORT/api/v1/namespaces/$NS/finalize"
done

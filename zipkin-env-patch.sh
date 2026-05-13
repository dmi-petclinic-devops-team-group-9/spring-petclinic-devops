#!/bin/bash
# Patches all PetClinic deployments with the correct Zipkin endpoint
for service in config-server discovery-server api-gateway customers-service vets-service visits-service genai-service admin-server; do
  kubectl set env deployment/$service \
    -n petclinic \
    MANAGEMENT_ZIPKIN_TRACING_ENDPOINT=http://zipkin.petclinic.svc.cluster.local:9411/api/v2/spans
  echo "✅ Patched $service"
done

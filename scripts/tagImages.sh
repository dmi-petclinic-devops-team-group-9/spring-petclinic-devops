#!/bin/bash
ACR="petclinic11acr.azurecr.io"
ACR_PREFIX="${ACR}/petclinic"
TAG=${1:-latest}

SERVICES=(
  "spring-petclinic-admin-server"
  "spring-petclinic-api-gateway"
  "spring-petclinic-config-server"
  "spring-petclinic-customers-service"
  "spring-petclinic-discovery-server"
  "spring-petclinic-genai-service"
  "spring-petclinic-vets-service"
  "spring-petclinic-visits-service"
)

for svc in "${SERVICES[@]}"; do
  docker tag "${ACR_PREFIX}/${svc}:latest" "${ACR_PREFIX}/${svc}:${TAG}"
  echo "  ✓ Tagged: ${ACR_PREFIX}/${svc}:${TAG}"
done

#!/bin/bash
ACR="petclinic11acr.azurecr.io"
ACR_PREFIX="${ACR}/petclinic"

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

echo "Logging in to ACR..."
az acr login --name petclinic11acr

for svc in "${SERVICES[@]}"; do
  IMAGE="${ACR_PREFIX}/${svc}:latest"
  echo "Pushing: ${IMAGE}"
  docker push "$IMAGE"
  echo "  ✓ Done"
done

echo ""
az acr repository list --name petclinic11acr --output table

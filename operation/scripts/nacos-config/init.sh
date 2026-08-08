#!/bin/sh
set -eu

NACOS_URL="http://nacos:8848/nacos"
NAMESPACE_ID="middle"

publish_config() {
  config_file="$1"
  data_id="$(basename "${config_file}")"

  result="$(
    curl --fail --silent --request POST \
      "${NACOS_URL}/v1/cs/configs" \
      --data-urlencode "tenant=${NAMESPACE_ID}" \
      --data-urlencode "group=DEFAULT_GROUP" \
      --data-urlencode "dataId=${data_id}" \
      --data-urlencode "type=yaml" \
      --data-urlencode "content@${config_file}"
  )"
  test "${result}" = "true"
  printf 'Published %s\n' "${data_id}"
}

namespaces="$(curl --fail --silent "${NACOS_URL}/v1/console/namespaces")"
if ! printf '%s' "${namespaces}" | grep -q "\"namespace\":\"${NAMESPACE_ID}\""; then
  result="$(
    curl --fail --silent --request POST \
      "${NACOS_URL}/v1/console/namespaces" \
      --data-urlencode "customNamespaceId=${NAMESPACE_ID}" \
      --data-urlencode "namespaceName=${NAMESPACE_ID}" \
      --data-urlencode "namespaceDesc=Local development"
  )"
  test "${result}" = "true"
fi

for config_file in /init/config/*.yml; do
  publish_config "${config_file}"
done

result="$(
  curl --fail --silent --request POST \
    "${NACOS_URL}/v1/cs/configs" \
    --data-urlencode "tenant=${NAMESPACE_ID}" \
    --data-urlencode "group=SEATA_GROUP" \
    --data-urlencode "dataId=seataServer.properties" \
    --data-urlencode "type=properties" \
    --data-urlencode "content@/init/seataServer.properties"
)"
test "${result}" = "true"
printf 'Published seataServer.properties\n'

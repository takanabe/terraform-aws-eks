cat <<EOF > ${kubeconfig}
apiVersion: v1
kind: Config
clusters:
- name: ${cluster_name}
  cluster:
    certificate-authority-data: ${ca_data}
    server: ${endpoint}
users:
- name: ${cluster_name}
  user:
    token: ${token}
contexts:
- name: ${cluster_name}
  context:
    cluster: ${cluster_name}
    user: ${cluster_name}
    namespace: ${namespace}
current-context: ${cluster_name}
EOF

kubectl --kubeconfig=${kubeconfig} apply -f -<<EOF
${manifest}
EOF

rm ${kubeconfig}

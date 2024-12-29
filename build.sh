read -p "Whats your provider domain name?: (akashprovid.com, 4090.akashgpu.com) " usr_domain_name
read -p "What is your Github Auth Toeken: " usr_auth_token
read -p "What is the first two octects internal IP of the cluster?: (192.168. or 172.20. ): " usr_Internal_IP
read -p "What is the Node name: " usr_node_name
read -p "What is the Github username?: " usr
read -p "What is the Github Repo name where the config files are located?:" usr_repo

echo "Downloading config files"

cd ~/
mkdir provider
cd provider

base_url="https://raw.githubusercontent.com/$usr/$usr_repo/main"

# Download config files
wget --header "Authorization: token $usr_auth_token" "$base_url/providerBuild.sh"
wget --header "Authorization: token $usr_auth_token" "$base_url/k3sAndProviderServices.sh"
wget --header "Authorization: token $usr_auth_token" "$base_url/$usr_domain_name/provider.yaml"
wget --header "Authorization: token $usr_auth_token" "$base_url/$usr_domain_name/cert-manager-values.yaml"
wget --header "Authorization: token $usr_auth_token" "$base_url/$usr_domain_name/dns-challenge-config.yaml"
wget --header "Authorization: token $usr_auth_token" "$base_url/$usr_domain_name/ingress-nginx-custom.yaml"
wget --header "Authorization: token $usr_auth_token" "$base_url/$usr_domain_name/rook-ceph-cluster.values.yml"
wget --header "Authorization: token $usr_auth_token" "$base_url/$usr_domain_name/wildcard-cert-request.yaml"

echo "Download completed!"

chmod +x providerBuild.sh
chmod +x k3sAndProviderServices.sh

./k3sAndProviderServices.sh  -s provider.$usr_domain_name -g -n $usr_Internal_IP -a

./providerBuild.sh  -d $usr_domain_name -g -w $usr_node_name -p -s -b beta3

kubectl label sc beta3 akash.network=true

helm repo add jetstack https://charts.jetstack.io
helm repo update

helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.14.3 \
  --set installCRDs=true


  kubectl apply -f cert-manager-values.yaml

  kubectl apply -f dns-challenge-config.yaml

  kubectl apply -f wildcard-cert-request.yaml


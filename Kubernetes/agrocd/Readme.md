# Install Agro CD 

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.7.2/manifests/install.yaml

kubectl apply -n argocd -k https://github.com/argoproj/argo-cd/manifests/crds\?ref\=stable


# IAC 

Tofu takes care of configuring the agrocd with app that we need for this repository.
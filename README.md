# Airflow on Kubernetes

Run Airflow on K8s in AWS. We are all running the same stuff. This won't be exactly what you need. This is meant to be a starting point to waste less engineering time.

## EKS Deployment Networking

The example EKS cluster in this repo is configured to allow both private and public access. Private access is done through private subnetting via a NAT gateway. Public access is controlled via allowlisting in the [EKS Security Group](./terraform/modules/airflow/variables.tf#L23). If you have a VPN or want to use a jumpbox, you can restrict EKS to only private access and configure access from your private network.

## Database

The main production database for this example is RDS - Postgres. There is a local version of a postgres database which runs inside of k8s. This is only for local development.

## Getting Started

### Prerequisites

1. [AWS account CLI configured locally](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html).
2. [Install Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).
3. [Install Make](https://formulae.brew.sh/formula/make)
4. Install Local Dependencies (Optional) - `make install-requirements`

### Run Airflow locally

1. Create and Export the .env file variables - `export $(cat .env)`. __Hint: the [.env template](.env.template) file shows which variables you will need to define in your .env file__. 
2. Build the Airflow image locally - `make build-minikube-airflow-image`
3. Apply the dev k8s config - `make set-kube-secrets-local`
4. Apply the dev k8s config - `make apply-kube-manifests-local`
5. Port forward to the local webserver et voilà - `kubectl port-forward svc/airflow-webserver 8080:8080 --namespace airflow`

### Run Airflow on AWS

1. Create and Export the .env file variables - `export $(cat .env)`. __Hint: the [.env template](.env.template) file shows which variables you will need to define in your .env file__.
2. Build the Terraform plans, `cd terraform/us-west-2 && terraform apply`.  __Hint: don't forget to [allowlist](./terraform/modules/k8s/variables.tf#L23) your IP or connect via a private network__.
3. Update local kubeconfig to point to the AWS EKS cluster, `make update-kubeconfig`.
4. Build and push the Airflow image to ECR, `make push-ecr-airflow-image`.
5. Set secrets in EKS, `make set-kube-secrets-prod`.
6. Apply kustomize manifests, `make apply-kube-manifests-prod`
7. Port forward to the local webserver et voilà - `kubectl port-forward svc/airflow-webserver 8080:8080 --namespace airflow`

## Common Commands

```bash
# Get all pods in the airflow namespace
kubectl get pods -n airflow

# Port forward the webserver to localhost:8080
kubectl port-forward svc/airflow-webserver 8080:8080 --namespace airflow

# Port forward the PG database to localhost:5432
kubectl port-forward svc/postgres 5432:5432 --namespace airflow

# Get the los for a pod
kubectl logs ${POD_NAME} -n airflow --all-containers --follow

# Open an interactive shell in a running container
kubectl exec --stdin --tty -n airflow -c scheduler ${POD_NAME} -- /bin/sh

# Print the plaintext of a kube secret
kubectl get secret postgres -n airflow -o json | jq -r '.data.connection' | base64 --decode

# Restart a pod
kubectl rollout restart deployment airflow-webserver -n airflow

# Delete all pods in a namespace
kubectl delete pods --all -n airflow
```

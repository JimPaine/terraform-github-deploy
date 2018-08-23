# terraform-github-deploy

Deploys a new "empty" App Service and configure a GitHub repo webhook to call ont the kudu deploy endpoint.

## Step 1

Create a GitHub personal access token

## Step 2

Either update the github token in main.tf or pass it in as a variable on the commandline.

## Step 3

Login to the Azure CLI

```
    az login
```

## Step 4

Run terraform

```
    terraform init

    terraform apply -auto-approve \
        -var "githubrepo=[githubrepo]" \
        -var "resource_name=[resource_name]" \
        -var "github_token=[github_token]"
```

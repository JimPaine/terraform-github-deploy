variable "resource_name" {
    default = "githubdeploy"
}

variable "githubrepo" {
    default = "terraform-github-deploy-demoapp"
}

variable "github_token" {
    default = "[token]"
}

provider "azurerm" {
  version = "~> 1.13"
}

provider "random" {
  version = "~> 1.3"
}

provider "github" {
  version      = "1.2.1"
  token        = "${var.github_token}"
  organization = "JimPaine"
}

resource "azurerm_resource_group" "demo" {
  name     = "${var.resource_name}"
  location = "northeurope"
}

resource "random_id" "demo" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = "${azurerm_resource_group.demo.name}"
  }

  byte_length = 2
}

resource "azurerm_storage_account" "demo" {
  name                     = "${var.resource_name}${random_id.demo.dec}store"
  resource_group_name      = "${azurerm_resource_group.demo.name}"
  location                 = "${azurerm_resource_group.demo.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_app_service_plan" "demo" {
  name                = "azure-functions-${var.resource_name}-service-plan"
  location            = "${azurerm_resource_group.demo.location}"
  resource_group_name = "${azurerm_resource_group.demo.name}"

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "demo" {
  name                      = "${var.resource_name}${random_id.demo.dec}"
  location                  = "${azurerm_resource_group.demo.location}"
  resource_group_name       = "${azurerm_resource_group.demo.name}"
  app_service_plan_id       = "${azurerm_app_service_plan.demo.id}"

  site_config {
    scm_type = "LocalGit"
  }
}
 
resource "github_repository_webhook" "demo" {
  repository = "${var.githubrepo}"

  name = "web"

  configuration {
    url          = "https://${azurerm_app_service.demo.site_credential.0.username}:${azurerm_app_service.demo.site_credential.0.password}@${var.resource_name}${random_id.demo.dec}.scm.azurewebsites.net/deploy"
    content_type = "json"
    insecure_ssl = false
  }

  active = true

  events = ["push"]
}
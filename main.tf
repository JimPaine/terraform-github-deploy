variable "resource_name" {
    default = "githubdeploy"
}

variable "githubrepo" {
    default = "terraform-github-deploy-demoapp"
}

variable "github_token" {
    default = "token"
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
  organization = "org"
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
  kind                = "FunctionApp"

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_function_app" "demo" {
  name                      = "${var.resource_name}${random_id.demo.dec}"
  location                  = "${azurerm_resource_group.demo.location}"
  resource_group_name       = "${azurerm_resource_group.demo.name}"
  app_service_plan_id       = "${azurerm_app_service_plan.demo.id}"
  storage_connection_string = "${azurerm_storage_account.demo.primary_connection_string}"

  # looks like at the moment for v2 http version has to be http1.1 and app has to be 32bit
  version = "beta"

  app_settings {
    FUNCTIONS_EXTENSION_VERSION = "2.0.11961-alpha" #temp pin to avoid breaking changes in next release
  }

  identity {
    type = "SystemAssigned"
  }
}
 
resource "github_repository_webhook" "demo" {
  repository = "${var.githubrepo}"

  name = "web"

  configuration {
    url          = "https://${azurerm_function_app.demo.site_credential.0.username}:${azurerm_function_app.demo.site_credential.0.password}@${var.resource_name}${random_id.demo.dec}.scm.azurewebsites.net/deploy"
    content_type = "json"
    insecure_ssl = false
  }

  active = true

  events = ["push"]
}
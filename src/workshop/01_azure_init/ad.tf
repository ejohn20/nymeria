resource "azuread_application" "github" {
  display_name    = "github-ad-app"
  identifier_uris = ["api://nymeria-workshop"]

  web {
    implicit_grant {
      access_token_issuance_enabled = true
      id_token_issuance_enabled     = true
    }
  }
}

resource "azuread_service_principal" "github" {
  application_id = azuread_application.github.application_id
}

resource "azuread_application_password" "github" {
  application_object_id = azuread_application.github.id
  display_name          = "github-long-lived-credential"
  end_date_relative     = "4392h" # 6 months for testing, not best practice
}

resource "azuread_application_federated_identity_credential" "github" {
  application_object_id = azuread_application.github.id
  display_name          = "github-federated-identity"
  description           = "Deployments for GH Action"
  audiences             = ["api://AzureADTokenExchange"]
  issuer                = "https://token.actions.githubusercontent.com"
  subject               = "repo:${var.github_organization}/${var.github_repository}:ref:refs/heads/main"
}

resource "azurerm_role_assignment" "github" {
  principal_id         = azuread_service_principal.github.object_id
  scope                = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${azurerm_resource_group.federated_identity.name}"
  role_definition_name = "Contributor"
}

resource "azurerm_user_assigned_identity" "cross_cloud" {
  name                = "cross-cloud-vm-${random_string.unique_id.result}"
  location            = var.location
  resource_group_name = azurerm_resource_group.federated_identity.name
}

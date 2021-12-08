provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "my_resource" {
  name     = "my-resource"
  location = "West Europe"
}

resource "azurerm_storage_account" "my_storage_account" {
  name                     = "mystorageaccount23123"
  resource_group_name      = azurerm_resource_group.my_resource.name
  location                 = azurerm_resource_group.my_resource.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_mssql_server" "my_mssql_server" {
  name                         = "sqlserverinmeta23432"
  resource_group_name          = azurerm_resource_group.my_resource.name
  location                     = azurerm_resource_group.my_resource.location
  version                      = "12.0"
  administrator_login          = "4dm1n157r470r"
  administrator_login_password = "4-v3ry-53cr37-p455w0rd"
}

resource "azurerm_mssql_database" "my_mssql_database" {
  name           = "my-mssql-database"
  server_id      = azurerm_mssql_server.my_mssql_server.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 4
  read_scale     = true
  sku_name       = "BC_Gen5_2"
  zone_redundant = true

  extended_auditing_policy {
    storage_endpoint                        = azurerm_storage_account.my_storage_account.primary_blob_endpoint
    storage_account_access_key              = azurerm_storage_account.my_storage_account.primary_access_key
    storage_account_access_key_is_secondary = true
    retention_in_days                       = 6
  }
}

resource "azurerm_app_service_plan" "my_appserviceplan" {
  name                = "my-appserviceplan"
  location            = azurerm_resource_group.my_resource.location
  resource_group_name = azurerm_resource_group.my_resource.name

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "my_appservice" {
  name                = "my-inmeta-as-0112"
  location            = azurerm_resource_group.my_resource.location
  resource_group_name = azurerm_resource_group.my_resource.name
  app_service_plan_id = azurerm_app_service_plan.my_appserviceplan.id

  site_config {
    dotnet_framework_version = "v4.0"
    scm_type                 = "LocalGit"
  }

  app_settings = {
    "SOME_KEY" = "some-value"
  }

  connection_string {
    name  = "Database"
    type  = "SQLServer"
    value = "Server=${azurerm_mssql_server.my_mssql_server.fully_qualified_domain_name};Database=${azurerm_mssql_database.my_mssql_database.name};Integrated Security=SSPI"
  }
}

resource "azurerm_storage_account" "static_storage" {
  name                      = "myinmetawebsite"
  resource_group_name       = azurerm_resource_group.my_resource.name
  location                  = azurerm_resource_group.my_resource.location
  account_kind              = "StorageV2"
  account_tier              = "Standard"
  account_replication_type  = "GRS"
  enable_https_traffic_only = true

  static_website {
    index_document = "index.html"
  }
}
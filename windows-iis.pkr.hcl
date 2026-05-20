packer {
  required_plugins {
    azure = {
      version = ">= 2.0.0"
      source  = "github.com/hashicorp/azure"
    }
  }
}

source "azure-arm" "windows-iis" {

  use_azure_cli_auth = true

  subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

  managed_image_resource_group_name = "rg-canada-prod"
  managed_image_name                = "windows-iis-image-${formatdate("YYYYMMDDhhmmss", timestamp())}"

  location = "canadacentral"
  vm_size  = "Standard_D2s_v5"

  os_type         = "Windows"
  image_publisher = "MicrosoftWindowsServer"
  image_offer     = "WindowsServer"
  image_sku       = "2022-datacenter-azure-edition"
  image_version   = "latest"

  communicator   = "winrm"
  winrm_use_ssl  = true
  winrm_insecure = true
  winrm_timeout  = "10m"
  winrm_username = "packer"

  azure_tags = {
    environment = "production"
    os          = "windows"
    server      = "iis"
  }

}

build {

  name = "windows-iis-build"

  sources = [
    "source.azure-arm.windows-iis"
  ]

  provisioner "powershell" {
    inline = [

      "Write-Host 'Installing IIS...'",

      "Install-WindowsFeature -name Web-Server -IncludeManagementTools",

      "Set-Content -Path C:\\inetpub\\wwwroot\\index.html -Value '<h1>IIS Server from Packer Image</h1>'",

      "Restart-Service W3SVC"
    ]
  }

}

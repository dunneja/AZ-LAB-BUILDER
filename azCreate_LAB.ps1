# ----------------------------------------------------------------------------
# -*- coding: utf-8 -*-
# ----------------------------------------------------------------------------
# Filename     : azCreate_AZLAB.ps1
# Application  : Azure Lab Builder.
# Version      : v1.0
# Author       : James Dunne <james.dunne1@gmail.com>
# License      : MIT-license
# Comment      : IMPORTANT!! DO NOT EDIT ANY VALUES IN THIS FILE!! 
#                All settings should be changed in Settings.json Only! 
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
# File Import Process - Settings.json <-- edit to change settings.
# ----------------------------------------------------------------------------
# Define Settings object to load settings.json variables into.
$SettingsObject          = Get-Content -Raw .\settings.json | Out-String | ConvertFrom-Json

# ----------------------------------------------------------------------------
# Azure Tenant / Resource Group Variables.
# ----------------------------------------------------------------------------
# Define Azure TentantID & Azure Resource group for the AZLAB Components.
$tenantid                = $SettingsObject.tenantid
$azureResourceGroup      = $SettingsObject.azureResourceGroup

# ----------------------------------------------------------------------------
# Azure Credential Variables - Passwords and Domain Name Information.
# ----------------------------------------------------------------------------
# Define Azure, SSH, ADDS & VM security credentials.
$vmAdminUser             = $SettingsObject.vmAdminUser
$vmAdminPwd              = $SettingsObject.vmAdminPwd
# Secure String Password used for VM's, SSH and AD Recovery Password.
$azureSecureStringPwd    = (ConvertTo-SecureString -String $vmAdminPwd -AsPlainText -Force)

# Define Active Directory Domain Name - Used to create AD Forrest.
$adDomain                = $SettingsObject.adDomain

# ----------------------------------------------------------------------------
# Azure Compute Variables.
# ----------------------------------------------------------------------------
# Global Azure Compute Variables. 
$azureVMRebootTimeout    = $SettingsObject.azureVMRebootTimeout
$azureRegionLocation     = $SettingsObject.azureRegionLocation
$azureLocation           = $azureRegionLocation.ToLower()
$azureVmSize             = $SettingsObject.azureVmSize

# Define AD Server Details.
$vmHostNameAD	         = $SettingsObject.vmHostNameAD

# Define the Windows VM marketplace image details.
$azureVmPublisherName    = $SettingsObject.azureVmPublisherName
$azureVmOffer            = $SettingsObject.azureVmOffer 
$azureVmSkus             = $SettingsObject.azureVmSkus

# Define SQL Server Details.
$vmHostNameSQL	         = $SettingsObject.vmHostNameSQL

# Define the SQL VM marketplace image details.
$azureVmPublisherNameSQL = $SettingsObject.azureVmPublisherNameSQL
$azureVmOfferSQL         = $SettingsObject.azureVmOfferSQL
$azureVmSkusSQL          = $SettingsObject.azureVmSkusSQL

# Define Linux Server Details.
$vmHostNameNix	         = $SettingsObject.vmHostNameNix
#Define the Linux VM marketplace image details.
$azureVmPublisherNameNix = $SettingsObject.azureVmPublisherNameNix
$azureVmOfferNix         = $SettingsObject.azureVmOfferNix
$azureVmSkusNix          = $SettingsObject.azureVmSkusNix
$azureVMVersion          = $SettingsObject.azureVMVersion

# ----------------------------------------------------------------------------
# Azure Storage Variables.
# ----------------------------------------------------------------------------
$azureVmOsDiskNameAD     = $vmHostNameAD + $SettingsObject.azureVmOsDiskName
$azureVmOsDiskNameSQL    = $vmHostNameSQL + $SettingsObject.azureVmOsDiskName
$azureVmOsDiskNameNix    = $vmHostNameNix + $SettingsObject.azureVmOsDiskName
$azureStorageAccountType = $SettingsObject.azureStorageAccountType

# ----------------------------------------------------------------------------
# Azure Networking Variables.
# ----------------------------------------------------------------------------

# Define Azure Subscription Networking. 
$azureVnetIPRange        = $SettingsObject.azureVnetIPRange
$azureVnetSubnet         = $SettingsObject.azureVnetSubnet
$azureVnetName           = $SettingsObject.azureVnetName
$azureSubnetName         = $SettingsObject.azureSubnetName

# Define the network interface information for AD server.
$azureNicNameAD          = $vmHostNameAD + $SettingsObject.azureNicName
$azureNsgNameAD          = $vmHostNameAD + $SettingsObject.azureNsgName

# Define the information information for SQL server.
$azureNicNameSQL         = $vmHostNameSQL + $SettingsObject.azureNicName
$azureNsgNameSQL         = $vmHostNameSQL + $SettingsObject.azureNsgName

# Define the information information for Linux server.
$azureNicNameNix         = $vmHostNameNix + $SettingsObject.azureNicName
$azureNsgNameNix         = $vmHostNameNix + $SettingsObject.azureNsgName
$azurePublicIpName       = $vmHostNameNix + $SettingsObject.azurePublicIpName
$LinuxVPNIPRange         = $SettingsObject.LinuxVPNIPRange

# This section will randomly generate a public dns Outputname for use in azure. 
$azureDNSNameLabel       = $SettingsObject.azureDNSNameLabel # *.uksouth.cloudapp.azure.com
$azureDNSNameSuffix      = Get-Random -Maximum 100
$azureDNSNamePublic      = $azureDNSNameLabel + $azureDNSNameSuffix

# ----------------------------------------------------------------------------
# Function - Header Function of the Program.
# ----------------------------------------------------------------------------
function Header {
        $line = "-" * 75
        Write-Host $line
        Write-Host "Azure Lab Builder - Standard Reference Architecture Script v1.0"
        Write-Host $line
        Write-Host "This script will deploy the following resources to your Azure Subscription:`n"
        Write-Host "Subscription ID: $tenantid `n"
        Write-Host "        * $azureResourceGroup - Resource Group`n"
        Write-Host "        * $azureVnetName - Virtual Network"
        Write-Host "        * $azureVnetIPRange - Virtual Network IP Range"
        Write-Host "        * $azureVnetIPRange - Virtual Network Subnet`n"
        Write-Host "        * $vmHostNameNix - Linux VPN Virtual Machine"
        Write-Host "        * $azureNicNameNix - Linux VPN VM Virtual Network Card"
        Write-Host "        * $azureVmOsDiskNameNix - Linux VPN VM OS Disk"
        Write-Host "        * $azurePublicIpName - Linux VPN VM Public IP"
        Write-Host "        * $azureNsgNameNix - Linux VPN VM Network Security Group`n"
        Write-Host "        * $vmHostNameAD - AD Virtual Machine"
        Write-Host "        * $azureNicNameAD - AD VM Virtual Network Card"
        Write-Host "        * $azureVmOsDiskNameAD - AD VM OS Disk"
        Write-Host "        * $azureNsgNameAD - AD VM Network Security Group`n"
        Write-Host "        * $vmHostNameSQL - SQL Virtual Machine"
        Write-Host "        * $azureNicNameSQL - SQL VM Virtual Network Card"
        Write-Host "        * $azureVmOsDiskNameSQL - SQL VM OS Disk"
        Write-Host "        * $azureNsgNameSQL - SQL VM Network Security Group`n"
        Write-Host "This script will deploy the following services to VM $vmHostNameAD :`n"
        Write-Host "        * Active Directory Domain Services`n"
        Write-Host "          - The Domain $adDomain will be created automatically`n"
        Write-Host "        * Active Directory Certificate Services (EnterpriseRootCA)`n"
        Write-Host "          - Active Directory Certificate will be installed.`n"
        Write-Host "          - ADCS Web Enrollment Service will be installed.`n"
        Write-Host "This script will deploy the following services to VM $vmHostNameNix :`n"
        Write-Host "        * Open Connect / OCServ VPN Server`n"
        Write-Host "          - The SSL Cert for the public domain name will be created automatically.`n"
        Write-Host "          - The UFW Settings and routing will be configured automatically.`n"
        Write-Host "NOTE: Edit 'Settings.json' to change any of the above parameters"
        Write-Host $line
}
# ----------------------------------------------------------------------------
# Function - Azure Dependencies Check function. Installs what is missing. 
# ----------------------------------------------------------------------------
function AZDepChk {
        Write-Host "`n- Please ensure you have installed AZURE-CLI before running this script!"
        Write-Host "- This can be downloaded from https://aka.ms/installazurecliwindows "
        Write-Host "- Download and install the latest release of the Azure CLI."
        Write-Host "- When the installer asks if it can make changes to your computer," 
        Write-Host "  click the 'Yes' box.`n"
        Write-Host "- Checking if Azure Cmdlet is installed on system..`n"
    if (Get-Module -ListAvailable -Name Az.*) {
        Write-Host "  * Az Module exists! We are cooking on gas!`n"
        Import-Module Az
    } 
    else {
        Write-Host "* Az Module does not exist! We have a flat tyre..`n"
        Write-Host "* Installing AZ Module..`n"
        Install-Module Az
        Import-Module Az
        Write-Host "* OK.. Now we're cooking on gas!`n"
    }
        Read-Host "All ready, press any key to continue with Azure Account Connect or 'CTRL-C' to Quit."
}
# ----------------------------------------------------------------------------
# Function - Azure Connect Function. Opens a PS window to login from.
# ----------------------------------------------------------------------------
function AZAccountConnect {
    # login into Az Account
    Write-Host "`n  * Logging into Azure Subscription.. (Select Account from Powershell Prompt Window)"
    Connect-AzAccount -tenantid $tenantid 
}
# ----------------------------------------------------------------------------
# Function - Create Azure Resources Function. Creates RG and VNET.
# ----------------------------------------------------------------------------
function CreateAzureResources {
    #Read-Host "All ready, press any key to continue with Azure Resources or 'CTRL-C' to Quit." "`n"
    Write-Host "  * Creating Resource Group $azureResourceGroup..`n"
    #az group create --location $azureLocation --name $azureResourceGroup --output table
    New-AzResourceGroup -Name $azureResourceGroup -Location $azureLocation
    Write-Host "`n  * Creating Vnet: $azureVnetName on $azureResourceGroup With Subnet Name: $azureSubnetName ...`n"
    az network vnet create --address-prefixes $azureVnetIPRange --name $azureVnetName --resource-group $azureResourceGroup --subnet-name $azureSubnetName --subnet-prefixes $azureVnetSubnet --output table
    }
# ----------------------------------------------------------------------------
# Function - Create Active Directory Virtual Machine & Resources.
# ----------------------------------------------------------------------------
function CreateADVMResources {
    #Read-Host "All ready, press any key to continue with AD VM Build or 'CTRL-C' to Quit."
    Write-Host "  * Gathering vNet/Subnet Information from $azureVnetName\$azureSubnetName`n"
    # Get the subnet details for the specified virtual network + subnet combination.
    $azureVnetSubnet = (Get-AzVirtualNetwork -Name $azureVnetName -ResourceGroupName $azureResourceGroup).Subnets | Where-Object { $_.Name -eq $azureSubnetName }
    Write-Host "  * Creating Security Rule/s and Network Security Group $azureNsgNameAD `n"
    # Create RDP Security Rule for Azure Vnet.
    $rdpRule = New-AzNetworkSecurityRuleConfig -Name "Allow_RDP" -Description "Allow RDP" -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix $LinuxVPNIPRange -SourcePortRange * -DestinationAddressPrefix $azureVnetIPRange -DestinationPortRange 3389
    # Create DNS Security Rule for VPN.
    $dnsRule = New-AzNetworkSecurityRuleConfig -Name "Allow_DNS" -Description "Allow DNS" -Access Allow -Protocol Tcp -Direction Inbound -Priority 103 -SourceAddressPrefix $LinuxVPNIPRange -SourcePortRange * -DestinationAddressPrefix $azureVnetIPRange -DestinationPortRange 53
    # Create Network Security Group
    $nsGroup = New-AzNetworkSecurityGroup -ResourceGroupName $azureResourceGroup -Location $azureLocation -Name $azureNsgNameAD -SecurityRules $rdpRule,$dnsRule
    Write-Host "  * Creating vNic $azureNicNameAD`n"
    # Create the NIC and associate the private subnet.
    $azureNIC = New-AzNetworkInterface -Name $azureNicNameAD -ResourceGroupName $azureResourceGroup -Location $azureLocation -SubnetId $azureVnetSubnet.Id
    # Associate the NSG to the NIC
    $azureNIC.NetworkSecurityGroup = $nsGroup
    Set-AzNetworkInterface -NetworkInterface $azureNIC | Out-null
    # Store the credentials for the local admin account.
    $vmCredentials = New-Object System.Management.Automation.PSCredential ($vmAdminUser, $azureSecureStringPwd)
    Write-Host "  * Defining Settings for new VM $vmHostNameAD `n"
    # Define the parameters for the new virtual machine.
    $VirtualMachine = New-AzVMConfig -VMName $vmHostNameAD -VMSize $azureVmSize
    $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $vmHostNameAD -Credential $vmCredentials -ProvisionVMAgent -EnableAutoUpdate
    $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $azureNIC.Id
    $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName $azureVmPublisherName -Offer $azureVmOffer -Skus $azureVmSkus -Version $azureVMVersion
    $VirtualMachine = Set-AzVMBootDiagnostic -VM $VirtualMachine -Disable
    $VirtualMachine = Set-AzVMOSDisk -VM $VirtualMachine -StorageAccountType $azureStorageAccountType -Caching ReadWrite -Name $azureVmOsDiskNameAD -CreateOption FromImage
    Write-Host "  * Creating new VM $vmHostNameAD `n"
    # Create the virtual machine.
    New-AzVM -ResourceGroupName $azureResourceGroup -Location $azureLocation -VM $VirtualMachine -Verbose | Out-null
}
# ----------------------------------------------------------------------------
# Function - Create Microsoft SQL Server Virtual Machine & Resources.
# ----------------------------------------------------------------------------
    function CreateSQLVMResources {
   # Read-Host "All ready, press any key to continue with SQL VM Build or 'CTRL-C' to Quit."
    Write-Host "`n  * Gathering vNet/Subnet Information from $azureVnetName\$azureSubnetName`n"
    # Get the subnet details for the specified virtual network + subnet combination.
    $azureVnetSubnet = (Get-AzVirtualNetwork -Name $azureVnetName -ResourceGroupName $azureResourceGroup).Subnets | Where-Object { $_.Name -eq $azureSubnetName }
    Write-Host "  * Creating Security Rule/s and Network Security Group $azureNsgNameSQL `n"
    # Create RDP Security Rule for Vnet.
    $rdpRule = New-AzNetworkSecurityRuleConfig -Name "Allow_RDP" -Description "Allow RDP" -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix $LinuxVPNIPRange -SourcePortRange * -DestinationAddressPrefix $azureVnetIPRange -DestinationPortRange 3389
    # Create SQL Security Rule for Vnet.
    $SQLRule = New-AzNetworkSecurityRuleConfig -Name "Allow_SQL" -Description "Allow SQL" -Access Allow -Protocol Tcp -Direction Inbound -Priority 102 -SourceAddressPrefix $azureVnetIPRange -SourcePortRange * -DestinationAddressPrefix $azureVnetIPRange -DestinationPortRange 1433
    # Create Network Security Group
    $nsGroup = New-AzNetworkSecurityGroup -ResourceGroupName $azureResourceGroup -Location $azureLocation -Name $azureNsgNameSQL -SecurityRules $rdpRule,$SQLRule
    Write-Host "  * Creating vNic $azureNicNameSQL`n"
    # Create the NIC and associate the private subnet.
    $azureNIC = New-AzNetworkInterface -Name $azureNicNameSQL -ResourceGroupName $azureResourceGroup -Location $azureLocation -SubnetId $azureVnetSubnet.Id
    # Associate the NSG to the NIC
    $azureNIC.NetworkSecurityGroup = $nsGroup
    Set-AzNetworkInterface -NetworkInterface $azureNIC | Out-null
    # Store the credentials for the local admin account.
    $vmCredentials = New-Object System.Management.Automation.PSCredential ($vmAdminUser, $azureSecureStringPwd)
    Write-Host "  * Defining Settings for new VM $vmHostNameSQL `n"
    # Define the parameters for the new virtual machine.
    $VirtualMachine = New-AzVMConfig -VMName $vmHostNameSQL -VMSize $azureVmSize
    $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $vmHostNameSQL -Credential $vmCredentials -ProvisionVMAgent -EnableAutoUpdate
    $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $azureNIC.Id
    $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName $azureVmPublisherNameSQL -Offer $azureVmOfferSQL -Skus $azureVmSkusSQL -Version $azureVMVersion
    $VirtualMachine = Set-AzVMBootDiagnostic -VM $VirtualMachine -Disable
    $VirtualMachine = Set-AzVMOSDisk -VM $VirtualMachine -StorageAccountType $azureStorageAccountType -Caching ReadWrite -Name $azureVmOsDiskNameSQL -CreateOption FromImage
    Write-Host "  * Creating new VM $vmHostNameSQL `n"
    # Create the virtual machine.
    New-AzVM -ResourceGroupName $azureResourceGroup -Location $azureLocation -VM $VirtualMachine -Verbose | Out-null
    addomainjoin
    }
# ----------------------------------------------------------------------------
# Function - Create Linux VPN Server Virtual Machine & Resources.
# ----------------------------------------------------------------------------
Function CreateNixVMResources {
    #Read-Host "All ready, press any key to continue with Linux VPN VM Build or 'CTRL-C' to Quit."
    Write-Host "  * Gathering vNet/Subnet Information from $azureVnetName\$azureSubnetName `n"
    #Get the subnet details for the specified virtual network + subnet combination.
    $azureVnetSubnet = (Get-AzVirtualNetwork -Name $azureVnetName -ResourceGroupName $azureResourceGroup).Subnets | Where-Object { $_.Name -eq $azureSubnetName }
    Write-Host "  * Creating Security Rule/s and Network Security Group $azureNsgNameNix `n"
    #Create SSH Security Rule
    $sshRule = New-AzNetworkSecurityRuleConfig -Name "Allow_SSH" -Description "Allow SSH" -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix $LinuxVPNIPRange -SourcePortRange * -DestinationAddressPrefix $azureVnetIPRange -DestinationPortRange 22
    #Create HTTP/S Security Rule
    $webRule = New-AzNetworkSecurityRuleConfig -Name "Allow_Web" -Description "Allow HTTP/S" -Access Allow -Protocol * -Direction Inbound -Priority 101 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 80,443
    #Create Network Security Group
    $nsGroup = New-AzNetworkSecurityGroup -ResourceGroupName $azureResourceGroup -Location $azureLocation -Name $azureNsgNameNix -SecurityRules $webRule,$sshRule
    Write-Host "  * Creating Static Public IP Address with DNS Name $azureDNSNamePublic.$azurelocation.cloudapp.azure.com `n"
    $azurePublicIP = New-AzPublicIpAddress -Name $azurePublicIpName -DomainNameLabel $azureDNSNamePublic -ResourceGroupName $azureResourceGroup -Location $azureLocation -AllocationMethod Static
    Write-Host "  * Creating vNic $azureNicNameNix"
    #Create the NIC and associate the private subnet.
    $azureNIC = New-AzNetworkInterface -Name $azureNicNameNix -ResourceGroupName $azureResourceGroup -Location $azureLocation -SubnetId $azureVnetSubnet.Id -PublicIpAddressId $azurePublicIP.Id
    #Associate the NSG to the NIC
    $azureNIC.NetworkSecurityGroup = $nsGroup
    Set-AzNetworkInterface -NetworkInterface $azureNIC | Out-null
    #Store the credentials for the local admin account.
    $vmCredentials = New-Object System.Management.Automation.PSCredential ($vmAdminUser, $azureSecureStringPwd)
    Write-Host "  * Defining Settings for new Linux VM $vmHostNameNix `n"
    #Define the parameters for the new virtual machine.Y
    $VirtualMachine = New-AzVMConfig -VMName $vmHostNameNix -VMSize $azureVmSize
    $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Linux -ComputerName $vmHostNameNix -Credential $vmCredentials
    $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $azureNIC.Id
    $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName $azureVmPublisherNameNix -Offer $azureVmOfferNix -Skus $azureVmSkusNix -Version $azureVMVersion
    $VirtualMachine = Set-AzVMBootDiagnostic -VM $VirtualMachine -Disable
    $VirtualMachine = Set-AzVMOSDisk -VM $VirtualMachine -StorageAccountType $azureStorageAccountType -Caching ReadWrite -Name $azureVmOsDiskNameNix -CreateOption FromImage
    Write-Host "  * Creating new Linux VM $vmHostNameNix `n"
    #Create the virtual machine.
    New-AzVM -ResourceGroupName $azureResourceGroup -Location $azureLocation -VM $VirtualMachine -Verbose | Out-null
}
# ----------------------------------------------------------------------------
# Function - Install Active Directory Domain Services Function.
# ----------------------------------------------------------------------------
Function AddADDS {
    #Read-Host "All ready, press any key to continue with ADDS Installation or 'CTRL-C' to Quit."
    Write-Host "  * Installing Active Directory Domain Services on VM $vmHostNameAD `n"
    az vm run-command invoke -g $azureResourceGroup -n $vmHostNameAD --command-id RunPowerShellScript --scripts "Install-WindowsFeature -name AD-Domain-Services -IncludeManagementTools" 
    Write-Host "  * Rebooting VM $vmHostNameAD `n"
    az vm restart -g $azureResourceGroup -n $vmHostNameAD 
    Write-Host "    - Waiting $azureVMRebootTimeout seconds for VM $vmHostNameAD to reboot.. `n"
    Start-Sleep -Seconds $azureVMRebootTimeout
    Write-Host "  * Installing ADDS Forrest with Domain name $adDomain on $vmHostNameAD `n"
    az vm run-command invoke -g $azureResourceGroup -n $vmHostNameAD  --command-id RunPowerShellScript --scripts "Install-ADDSForest -DomainName $adDomain -SafeModeAdministratorPassword (ConvertTo-SecureString -String $azureSecureStringPwd -AsPlainText -Force) -InstallDNS -Force" 
}
# ----------------------------------------------------------------------------
# Function - Install Active Directory Certification Authority Function.
# ----------------------------------------------------------------------------
function AddADCS {
    #Read-Host "All ready, press any key to continue with ADCS Installation or 'CTRL-C' to Quit."
    Write-Host "  * Installing AD Certificate on $vmHostNameAD `n"
    az vm run-command invoke -g $azureResourceGroup -n $vmHostNameAD  --command-id RunPowerShellScript --scripts "Install-WindowsFeature -name AD-Certificate" 
    Write-Host "  * Installing AD CS Certification Authority Service on $vmHostNameAD `n"
    az vm run-command invoke -g $azureResourceGroup -n $vmHostNameAD  --command-id RunPowerShellScript --scripts "Install-AdcsCertificationAuthority -CAType EnterpriseRootCA -CACommonName $adDomain-CA -Force" 
    Write-Host "  * Installing ADCS Web Enrollment Service & Interface for Certificate Requests on $vmHostNameAD `n"
    az vm run-command invoke -g $azureResourceGroup -n $vmHostNameAD --command-id RunPowerShellScript --scripts "Install-WindowsFeature -name Adcs-Enroll-Web-Svc" 
    az vm run-command invoke -g $azureResourceGroup -n $vmHostNameAD --command-id RunPowerShellScript --scripts "Install-WindowsFeature -name Adcs-Web-Enrollment" 
    Write-Host "  * Adding user $vmAdminUser to IIS_IUSERS Group `n"
    az vm run-command invoke -g $azureResourceGroup -n $vmHostNameAD --command-id RunPowerShellScript --scripts "Add-ADGroupMember -Identity IIS_IUSRS -Members labadmin" 
}
# ----------------------------------------------------------------------------
# Function - Install OCServ / Open Connect VPN Server, Certbot and Configure. 
# ----------------------------------------------------------------------------
function AddVPNSvc {
    #Read-Host "All ready, press any key to continue with OCServ / Open Connect VPN Installation or 'CTRL-C' to Quit."
    Write-Host "  * Performing apt update on $vmHostNameNix `n"
    az vm run-command invoke -g $azureResourceGroup -n $vmHostNameNix --command-id RunShellScript --scripts "sudo apt update"
    Write-Host "  * Performing apt upgrade on $vmHostNameNix `n"
    az vm run-command invoke -g $azureResourceGroup -n $vmHostNameNix --command-id RunShellScript --scripts "sudo apt upgrade -y"
    Write-Host "  * Performing installation of ocserv vpn on $vmHostNameNix `n"
    az vm run-command invoke -g $azureResourceGroup -n $vmHostNameNix --command-id RunShellScript --scripts "sudo apt install ocserv -y"
    Write-Host "  * Enabling Port 22/TCP for SSH Connectivity on $vmHostNameNix `n"
    az vm run-command invoke -g $azureResourceGroup -n $vmHostNameNix --command-id RunShellScript --scripts "sudo ufw allow 22/tcp"
    Write-Host "  * Enabling Port 80/TCP for LetsEncrypt Certbot Connectivity on $vmHostNameNix `n"
    az vm run-command invoke -g $azureResourceGroup -n $vmHostNameNix --command-id RunShellScript --scripts "sudo ufw allow 80/tcp"
    Write-Host "  * Enabling Port 443/TCP+UDP for ocserv/Open Connect VPN Connectivity on $vmHostNameNix `n"
    az vm run-command invoke -g $azureResourceGroup -n $vmHostNameNix --command-id RunShellScript --scripts "sudo ufw allow 443/tcp"
    az vm run-command invoke -g $azureResourceGroup -n $vmHostNameNix --command-id RunShellScript --scripts "sudo ufw allow 443/udp"
    Write-Host "  * Enabling UFW Service on $vmHostNameNix `n"
    az vm run-command invoke -g $azureResourceGroup -n $vmHostNameNix --command-id RunShellScript --scripts "sudo ufw enable" 
    Write-Host "  * Restarting UFW Service on $vmHostNameNix `n"
    az vm run-command invoke -g $azureResourceGroup -n $vmHostNameNix --command-id RunShellScript --scripts "sudo systemctl restart ufw.service" 
    Write-Host "  * Performing installation of LetsEncrypt certbot on $vmHostNameNix `n"
    az vm run-command invoke -g $azureResourceGroup -n $vmHostNameNix --command-id RunShellScript --scripts "sudo apt install certbot -y" 
    Write-Host "  * Requesting SSL Certificate from LetsEncrypt for domain name $azureDNSNamePublic.$azureLocation.cloudapp.azure.com `n"
    az vm run-command invoke -g $azureResourceGroup -n $vmHostNameNix --command-id RunShellScript --scripts "sudo certbot certonly --standalone --preferred-challenges http --agree-tos --email labadmin@$azureDNSNamePublic.$azureLocation.cloudapp.azure.com -d $azureDNSNamePublic.$azureLocation.cloudapp.azure.com -n" 
    Write-Host "  * Creating Certificate folder for LetsEncrypt Issued Certs `n"
    az vm run-command invoke -g $azureResourceGroup -n $vmHostNameNix --command-id RunShellScript --scripts "sudo mkdir -p /etc/ocserv/certs" 
    Write-Host "  * Copying SSL Certs from Letsencrypt folder to ocserv certificate folder `n"
    az vm run-command invoke -g $azureResourceGroup -n $vmHostNameNix --command-id RunShellScript --scripts "sudo cp /etc/letsencrypt/live/$azureDNSNamePublic.$azureLocation.cloudapp.azure.com/fullchain.pem /etc/ocserv/certs" 
    az vm run-command invoke -g $azureResourceGroup -n $vmHostNameNix --command-id RunShellScript --scripts "sudo cp /etc/letsencrypt/live/$azureDNSNamePublic.$azureLocation.cloudapp.azure.com/privkey.pem /etc/ocserv/certs" 
    Write-Host "  * Updating /etc/sysctl.d/60-custom.conf with routing parameters `n"
    az vm run-command invoke -g $azureResourceGroup -n $vmHostNameNix --command-id RunShellScript --scripts "sudo echo 'net.ipv4.ip_forward = 1' | sudo tee /etc/sysctl.d/60-custom.conf" 
    az vm run-command invoke -g $azureResourceGroup -n $vmHostNameNix --command-id RunShellScript --scripts "sudo echo 'net.core.default_qdisc=fq' | sudo tee -a /etc/sysctl.d/60-custom.conf" 
    az vm run-command invoke -g $azureResourceGroup -n $vmHostNameNix --command-id RunShellScript --scripts "sudo echo 'net.ipv4.tcp_congestion_control=bbr' | sudo tee -a /etc/sysctl.d/60-custom.conf" 
    az vm run-command invoke -g $azureResourceGroup -n $vmHostNameNix --command-id RunShellScript --scripts "sudo sysctl -p /etc/sysctl.d/60-custom.conf" 
    Write-Host "  * Cloning ocserv & ufw config files from DUNNEJA github repo `n"
    az vm run-command invoke -g $azureResourceGroup -n $vmHostNameNix --command-id RunShellScript --scripts "git clone https://github.com/dunneja/ocserv.git /home/labadmin/ocserv/" 
    Write-Host "  * Copying ocserv.conf to /etc/ocserv/ folder. `n"
    az vm run-command invoke -g $azureResourceGroup -n $vmHostNameNix --command-id RunShellScript --scripts "sudo cp /home/labadmin/ocserv/ocserv.conf /etc/ocserv/" 
    Write-Host "  * Restarting the ocserv service. `n"
    az vm run-command invoke -g $azureResourceGroup -n $vmHostNameNix --command-id RunShellScript --scripts "sudo systemctl restart ocserv" 
    Write-Host "  * Copying before.rules to /etc/ufw/ folder. `n"
    az vm run-command invoke -g $azureResourceGroup -n $vmHostNameNix --command-id RunShellScript --scripts "sudo cp /home/labadmin/ocserv/before.rules /etc/ufw/" 
    Write-Host "  * Updating Owner for file before.rules to root for security purposes `n"
    az vm run-command invoke -g $azureResourceGroup -n $vmHostNameNix --command-id RunShellScript --scripts "sudo chown root:root /etc/ufw/before.rules" 
    Write-Host "  * Deleting UFW Port 80/tcp rule used for certbot LetsEncrypt cert generation. This is no longer needed now we have the goodies! `n"
    az vm run-command invoke -g $azureResourceGroup -n $vmHostNameNix --command-id RunShellScript --scripts "sudo ufw delete 80/tcp" 
    Write-Host "  * Restarting the UFW Service.`n"
    az vm run-command invoke -g $azureResourceGroup -n $vmHostNameNix --command-id RunShellScript --scripts "sudo systemctl restart ufw" 
    Write-Host "  * ocserv / Open Connect VPN Service is now configured`n"
}
function addomainjoin {
    $joinCred = New-Object pscredential -ArgumentList ([pscustomobject]@{
            UserName = $null
            Password = $azureSecureStringPwd[0]
        })
    Write-Host "  * Getting Network Adapter Interface Index Value & Configuring DNS Servers`n"
    az vm run-command invoke -g $azureResourceGroup -n $vmHostNameSQL --command-id RunPowerShellScript --scripts "set-DnsClientServerAddress -InterfaceIndex (Get-NetAdapter | Select -ExpandProperty 'InterfaceIndex') -ServerAddresses ('10.0.0.4','8.8.8.8')" 
    Write-Host "  * Registering $vmHostNameSQL on domain $adDomain`n"
    az vm run-command invoke -g $azureResourceGroup -n $vmHostNameAD --command-id RunPowerShellScript --scripts "New-ADComputer -Name $vmHostNameSQL -AccountPassword (ConvertTo-SecureString -String $vmAdminPwd -AsPlainText -Force)" 
    Write-Host "  * joining $vmHostNameSQL to domain $adDomain`n" 
    az vm run-command invoke -g $azureResourceGroup -n $vmHostNameSQL --command-id RunPowerShellScript --scripts "Add-Computer -Domain $adDomain -Options UnsecuredJoin, PasswordPass -Credential $joinCred -Restart"
}
# ----------------------------------------------------------------------------
# Function - List All Resources Created In The Specified Resource Group.
# ----------------------------------------------------------------------------
function AZRGList {
    Write-Host " * Listing All Deployed Resources in Resource Group $azureResourceGroup :`n"
    az resource list -g $azureResourceGroup -o table
}
# ----------------------------------------------------------------------------
# Function - Program Footer Function.
# ----------------------------------------------------------------------------
function Footer {
    $line = "-" * 75
    Write-Host "`n"
    Write-Host $line
    Write-Host "Azure Lab Builder - Procedural Operation Completed!"
    Write-Host "Login to the Azure Portal and Review Resources Deployed. Enjoy! :o)"
    Write-Host $line
    Write-Host "Azure Portal: https://portal.azure.com/"
    Write-Host $line
    Write-Host "SSL VPN Server Address: $azureDNSNamePublic.$azureLocation.cloudapp.azure.com"
    Write-Host $line
}

# ----------------------------------------------------------------------------
# Azure LAB Build Process - Function Calls
# ----------------------------------------------------------------------------

# Start - Display Header.
Header

# Step 1 - Check Dependencies and install anything missing.
Write-Host "`nStep 1) - Checking AZ CMDLET dependencies."
AZDepChk

# Step 2 - Connect to Azure Subscription / Account.
Write-Host "`nStep 2) - Connecting to Azure Subscription."
AZAccountConnect

# Step 3 - Create Azure Resource Groups, networking and NSGs.
Write-Host "`nStep 3) - Creating Resource Group.`n"
CreateAzureResources

# Step 4 - Create AD VM Resources. 
Write-Host "`nStep 4) - Provisioning Active Directory Virtual Machine.`n"
CreateADVMResources

# Step 5 - Install Active Directory Domain Services on Provisioned AD VM.
Write-Host "`nStep 5) - Installing Active Directory Domain Services.`n"
AddADDS

# Step 6 - Install Active Directory Certificate Services
Write-Host "`nStep 6) - Installing Active Directory Certificate Services.`n"
AddADCS

# Step 7 - Create SQL VM Resources. 
Write-Host "`nStep 7) - Provisioning Microsoft SQL Server Virtual Machine.`n"
CreateSQLVMResources

# Step 8 - Create Linux VM Resources. 
Write-Host "`nStep 8) - Provisioning Linux VPN Server Virtual Machine.`n"
CreateNixVMResources

# Step 9 - Installing and Configuring Open Connect VPN on Linux Server.
Write-Host "`nStep 9) - Installing Open Connect (OCServ) VPN service on Linux Virtual Machine.`n"
AddVPNSvc

# Step 10 - Display Resources Deployed.
Write-Host "`nStep 10) - Displaying All Resources Deployed.`n"
AZRGList

# End - Display Footer.
Footer
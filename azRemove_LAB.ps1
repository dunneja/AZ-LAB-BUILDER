# ----------------------------------------------------------------------------
# -*- coding: utf-8 -*-
# ----------------------------------------------------------------------------
# Filename     : azRemove_AZLAB.ps1
# Application  : Azure Lab Builder.
# Version      : v1.0
# Author       : James Dunne <james.dunne1@gmail.com>
# License      : None
# Comment      : IMPORTANT!! DO NOT EDIT ANY VALUES IN THIS FILE!! 
#                All settings should be changed in Settings.json Only! 
# ----------------------------------------------------------------------------
# Define Settings object to load settings.json variables into.
$SettingsObject = Get-Content -Raw .\settings.json | Out-String | ConvertFrom-Json
$azLab = $SettingsObject.azureResourceGroup
Write-Host "  * Removing Resource Group $azLab"
Remove-AzResourceGroup $azLab -Force
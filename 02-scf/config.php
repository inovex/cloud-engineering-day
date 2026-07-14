<?php
// Minimal Nextcloud configuration for Cloud Foundry.
// trusted_domains is '*' so CF's dynamically assigned hostname is accepted.
$CONFIG = [
    'trusted_domains' => ['*'],
    'appstoreenabled' => false,
];

<?php
return [
    'app_url' => 'https://example.com/api',
    'db' => [
        'host' => 'localhost',
        'port' => 3306,
        'name' => 'sinematch',
        'user' => 'sinematch',
        'pass' => '',
        'charset' => 'utf8mb4',
    ],
    'security' => [
        'token_ttl_days' => 30,
        'rate_limit_per_minute' => 120,
    ],
    'ai' => [
        'enabled' => false,
        'base_url' => 'https://api.openai.com/v1',
        'api_key' => '',
        'model' => '',
    ],
    'tmdb' => [
        'api_key' => '',
    ],
    'iap' => [
        'mode' => 'production',
    ],
];

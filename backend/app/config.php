<?php
return [
    'app_url' => 'https://site-demo.com.tr',
    'db' => [
        'host' => 'localhost',
        'port' => 3306,
        'name' => 'ma',
        'user' => 'ma',
        'pass' => 'ik*uH8bQ$eyS4k0i',
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
        'api_key' => '508ae3ad712f67ca2cf29c2420f06015',
    ],
    'iap' => [
        'mode' => 'production',
    ],
];

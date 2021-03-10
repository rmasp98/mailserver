<?php
$config['log_driver'] = 'stdout';
$config['default_port'] = 993;
$config['smtp_port'] = 587;
$config['support_url'] = '';
$config['des_key'] = '$(head /dev/urandom | base64 | head -c 24)';
$config['zipdownload_selection'] = true;
$config['language'] = 'en_UK';
$config['mime_param_folding'] = 0;

$config['managesieve_port'] = 4190;
$config['managesieve_auth_type'] = 'plain';
$config['managesieve_usetls'] = true;

$config['password_driver'] = 'sql';
$config['password_minimum_length'] = 9;
$config['password_minimum_score'] = 1;
$config['password_confirm_current'] = true;
$config['password_query'] = 'CALL UpdatePassword(%u,%p,%o)';

// This is where the configurable options are placed

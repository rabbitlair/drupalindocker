
// Memcached settings
$conf['cache_inc'] = 'sites/all/modules/contrib/memcache/memcache.inc';
$conf['session_inc'] = 'sites/all/modules/contrib/memcache/memcache-session.inc';
$conf['memcache_extension'] = 'memcached';
$conf['memcache_servers'] = array(
  'memcached:11211' => 'default',
);
$conf['memcache_bins'] = array(
  'cache' => 'default',
  'cache_block' => 'default',
  'cache_filter' => 'default',
  'cache_form' => 'database',
  'cache_menu' => 'default',
  'cache_page' => 'default',
  'cache_update' => 'default',
);
$conf['memcache_options'] = array(
  Memcached::OPT_COMPRESSION => FALSE,
  Memcached::OPT_DISTRIBUTION => Memcached::DISTRIBUTION_CONSISTENT,
  Memcached::OPT_BINARY_PROTOCOL => TRUE,
);

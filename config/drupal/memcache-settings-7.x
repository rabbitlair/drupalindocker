
// Memcache settings
$conf['cache_backends'][] = 'sites/all/modules/contrib/memcache/memcache.inc';
$conf['cache_default_class'] = 'MemCacheDrupal';
$conf['cache_class_cache_form'] = 'DrupalDatabaseCache';
$conf['lock_inc'] = 'sites/all/modules/contrib/memcache/memcache-lock.inc';
$conf['page_cache_without_database'] = TRUE;
$conf['page_cache_invoke_hooks'] = FALSE;

$conf['memcache_servers'] = array('memcached:11211');
$conf['memcache_persistent'] = TRUE;
$conf['memcache_options'] = array(
  Memcached::OPT_COMPRESSION => TRUE,
  Memcached::OPT_BINARY_PROTOCOL => TRUE,
);


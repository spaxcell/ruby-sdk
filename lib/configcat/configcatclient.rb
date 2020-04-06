require 'configcat/interfaces'
require 'configcat/configcache'
require 'configcat/configfetcher'
require 'configcat/autopollingcachepolicy'
require 'configcat/manualpollingcachepolicy'
require 'configcat/lazyloadingcachepolicy'
require 'configcat/rolloutevaluator'

module ConfigCat
  class ConfigCatClient
    def initialize(sdk_key,
                   poll_interval_seconds:60,
                   max_init_wait_time_seconds:5,
                   on_configuration_changed_callback:nil,
                   cache_time_to_live_seconds:60,
                   config_cache_class:nil,
                   base_url:nil,
                   proxy_address:nil,
                   proxy_port:nil,
                   proxy_user:nil,
                   proxy_pass:nil)
      if sdk_key === nil
        raise ConfigCatClientException, "SDK Key is required."
      end
      @_sdk_key = sdk_key

      if config_cache_class
        @_config_cache = config_cache_class.new()
      else
        @_config_cache = InMemoryConfigCache.new()
      end

      if poll_interval_seconds > 0
        @_config_fetcher = CacheControlConfigFetcher.new(sdk_key, "p", base_url, proxy_address, proxy_port, proxy_user, proxy_pass)
        @_cache_policy = AutoPollingCachePolicy.new(@_config_fetcher, @_config_cache, poll_interval_seconds, max_init_wait_time_seconds, on_configuration_changed_callback)
      else
        if cache_time_to_live_seconds > 0
          @_config_fetcher = CacheControlConfigFetcher.new(sdk_key, "l", base_url, proxy_address, proxy_port, proxy_user, proxy_pass)
          @_cache_policy = LazyLoadingCachePolicy.new(@_config_fetcher, @_config_cache, cache_time_to_live_seconds)
        else
          @_config_fetcher = CacheControlConfigFetcher.new(sdk_key, "m", base_url, proxy_address, proxy_port, proxy_user, proxy_pass)
          @_cache_policy = ManualPollingCachePolicy.new(@_config_fetcher, @_config_cache)
        end
      end
    end

    def get_value(key, default_value, user=nil)
      config = @_cache_policy.get()
      if config === nil
        return default_value
      end
      return RolloutEvaluator.evaluate(key, user, default_value, config)
    end

    def get_all_keys()
      config = @_cache_policy.get()
      if config === nil
        return []
      end
      return config.keys
    end

    def force_refresh()
      @_cache_policy.force_refresh()
    end

    def stop()
      @_cache_policy.stop()
      @_config_fetcher.close()
    end

  end
end

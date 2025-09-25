package com.scrib.gatewayservice.filter;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cloud.gateway.filter.GatewayFilter;
import org.springframework.cloud.gateway.filter.factory.AbstractGatewayFilterFactory;
import org.springframework.data.redis.core.ReactiveRedisTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.http.server.reactive.ServerHttpResponse;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Mono;

import java.time.Duration;

@Component
public class RateLimitFilter extends AbstractGatewayFilterFactory<RateLimitFilter.Config> {
    
    @Autowired
    private ReactiveRedisTemplate<String, String> redisTemplate;
    
    public RateLimitFilter() {
        super(Config.class);
    }
    
    @Override
    public GatewayFilter apply(Config config) {
        return (exchange, chain) -> {
            String clientIp = exchange.getRequest().getRemoteAddress().getAddress().getHostAddress();
            String key = "rate_limit:" + clientIp;
            
            return redisTemplate.opsForValue().increment(key)
                    .flatMap(count -> {
                        if (count == 1) {
                            // Set expiration on first request
                            return redisTemplate.expire(key, Duration.ofMinutes(1))
                                    .then(Mono.just(count));
                        }
                        return Mono.just(count);
                    })
                    .flatMap(count -> {
                        if (count > config.getMaxRequests()) {
                            ServerHttpResponse response = exchange.getResponse();
                            response.setStatusCode(HttpStatus.TOO_MANY_REQUESTS);
                            response.getHeaders().add("X-RateLimit-Limit", String.valueOf(config.getMaxRequests()));
                            response.getHeaders().add("X-RateLimit-Remaining", "0");
                            return response.setComplete();
                        }
                        
                        ServerHttpResponse response = exchange.getResponse();
                        response.getHeaders().add("X-RateLimit-Limit", String.valueOf(config.getMaxRequests()));
                        response.getHeaders().add("X-RateLimit-Remaining", String.valueOf(config.getMaxRequests() - count));
                        
                        return chain.filter(exchange);
                    });
        };
    }
    
    public static class Config {
        private int maxRequests = 100; // Default: 100 requests per minute
        
        public int getMaxRequests() {
            return maxRequests;
        }
        
        public void setMaxRequests(int maxRequests) {
            this.maxRequests = maxRequests;
        }
    }
}

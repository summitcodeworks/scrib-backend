package com.scrib.gatewayservice.config;

import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.route.builder.RouteLocatorBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class GatewayConfig {

    @Bean
    public RouteLocator customRouteLocator(RouteLocatorBuilder builder) {
        return builder.routes()
                // User Service routes
                .route("user-service-exact", r -> r
                        .path("/api/users")
                        .filters(f -> f.rewritePath("/api/users", "/users"))
                        .uri("http://localhost:9201"))
                .route("user-service", r -> r
                        .path("/api/users/**")
                        .filters(f -> f.rewritePath("/api/users/(?<remaining>.*)", "/users/${remaining}"))
                        .uri("http://localhost:9201"))
                
                // Note Service routes
                .route("note-service-exact", r -> r
                        .path("/api/notes")
                        .filters(f -> f.rewritePath("/api/notes", "/notes"))
                        .uri("http://localhost:9202"))
                .route("note-service", r -> r
                        .path("/api/notes/**")
                        .filters(f -> f.rewritePath("/api/notes/(?<remaining>.*)", "/notes/${remaining}"))
                        .uri("http://localhost:9202"))
                
                // WebSocket routes
                .route("note-websocket", r -> r
                        .path("/ws/**")
                        .uri("http://localhost:9202"))
                
                // Search Service routes
                .route("search-service", r -> r
                        .path("/api/search/**")
                        .filters(f -> f.rewritePath("/api/search/(?<remaining>.*)", "/search/${remaining}"))
                        .uri("http://localhost:9203"))
                
                .build();
    }

}

package com.scrib.common.dto;

import jakarta.validation.constraints.Size;

public class SearchRequest {
    @Size(max = 100, message = "Query must not exceed 100 characters")
    private String query;
    
    private NoteDto.Visibility visibility;
    
    @Size(max = 50, message = "Language must not exceed 50 characters")
    private String language;
    
    private String username;
    
    private int page = 0;
    private int size = 20;

    // Constructors
    public SearchRequest() {}

    public SearchRequest(String query, NoteDto.Visibility visibility, String language, 
                        String username, int page, int size) {
        this.query = query;
        this.visibility = visibility;
        this.language = language;
        this.username = username;
        this.page = page;
        this.size = size;
    }

    // Getters and Setters
    public String getQuery() {
        return query;
    }

    public void setQuery(String query) {
        this.query = query;
    }

    public NoteDto.Visibility getVisibility() {
        return visibility;
    }

    public void setVisibility(NoteDto.Visibility visibility) {
        this.visibility = visibility;
    }

    public String getLanguage() {
        return language;
    }

    public void setLanguage(String language) {
        this.language = language;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public int getPage() {
        return page;
    }

    public void setPage(int page) {
        this.page = page;
    }

    public int getSize() {
        return size;
    }

    public void setSize(int size) {
        this.size = size;
    }
}

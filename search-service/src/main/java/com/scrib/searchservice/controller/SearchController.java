package com.scrib.searchservice.controller;

import com.scrib.common.dto.ApiResponse;
import com.scrib.common.dto.NoteDto;
import com.scrib.common.dto.SearchRequest;
import com.scrib.searchservice.service.SearchService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/search")
@CrossOrigin(origins = "*")
public class SearchController {
    
    @Autowired
    private SearchService searchService;
    
    @GetMapping("/notes")
    public ResponseEntity<ApiResponse<Page<NoteDto>>> searchNotes(@Valid SearchRequest searchRequest) {
        Page<NoteDto> results = searchService.searchNotes(searchRequest);
        return ResponseEntity.ok(ApiResponse.success(results));
    }
    
    @GetMapping("/notes/user/{userId}")
    public ResponseEntity<ApiResponse<Page<NoteDto>>> searchUserNotes(
            @PathVariable UUID userId, 
            @Valid SearchRequest searchRequest) {
        Page<NoteDto> results = searchService.searchUserNotes(userId, searchRequest);
        return ResponseEntity.ok(ApiResponse.success(results));
    }
    
    @GetMapping("/notes/public")
    public ResponseEntity<ApiResponse<Page<NoteDto>>> getPublicNotes(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Page<NoteDto> results = searchService.getPublicNotes(page, size);
        return ResponseEntity.ok(ApiResponse.success(results));
    }
    
    @GetMapping("/notes/user/{userId}/all")
    public ResponseEntity<ApiResponse<Page<NoteDto>>> getUserNotes(
            @PathVariable UUID userId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Page<NoteDto> results = searchService.getUserNotes(userId, page, size);
        return ResponseEntity.ok(ApiResponse.success(results));
    }
    
    @GetMapping("/notes/language/{language}")
    public ResponseEntity<ApiResponse<Page<NoteDto>>> getNotesByLanguage(
            @PathVariable String language,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Page<NoteDto> results = searchService.getNotesByLanguage(language, page, size);
        return ResponseEntity.ok(ApiResponse.success(results));
    }
    
    @GetMapping("/languages")
    public ResponseEntity<ApiResponse<List<String>>> getAvailableLanguages() {
        List<String> languages = searchService.getAvailableCodeLanguages();
        return ResponseEntity.ok(ApiResponse.success(languages));
    }
}

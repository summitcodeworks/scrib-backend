package com.scrib.noteservice.controller;

import com.scrib.common.dto.ApiResponse;
import com.scrib.common.dto.NoteDto;
import com.scrib.noteservice.entity.Note;
import com.scrib.noteservice.service.NoteService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@RestController
@RequestMapping("/notes")
public class NoteController {
    
    @Autowired
    private NoteService noteService;
    
    @PostMapping
    public ResponseEntity<ApiResponse<NoteDto>> createNote(@Valid @RequestBody NoteDto noteDto) {
        try {
            NoteDto createdNote = noteService.createNote(noteDto);
            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(ApiResponse.success("Note created successfully", createdNote));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error("Failed to create note: " + e.getMessage()));
        }
    }
    
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<NoteDto>> updateNote(@PathVariable UUID id, 
                                                          @Valid @RequestBody NoteDto noteDto) {
        try {
            NoteDto updatedNote = noteService.updateNote(id, noteDto);
            return ResponseEntity.ok(ApiResponse.success("Note updated successfully", updatedNote));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(e.getMessage()));
        }
    }
    
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<String>> deleteNote(@PathVariable UUID id,
                                                         @RequestParam UUID userId) {
        try {
            noteService.deleteNote(id, userId);
            return ResponseEntity.ok(ApiResponse.success("Note deleted successfully"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.error(e.getMessage()));
        }
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<NoteDto>> getNote(@PathVariable UUID id,
                                                      @RequestParam(required = false) UUID userId) {
        Optional<NoteDto> note;
        
        if (userId != null) {
            // Try to get user's note first
            note = noteService.getUserNoteById(id, userId);
            if (note.isEmpty()) {
                // Fallback to public note
                note = noteService.getPublicNoteById(id);
            }
        } else {
            // Only public notes
            note = noteService.getPublicNoteById(id);
        }
        
        return note.map(n -> ResponseEntity.ok(ApiResponse.success(n)))
                .orElse(ResponseEntity.notFound().build());
    }
    
    @GetMapping
    public ResponseEntity<ApiResponse<Page<NoteDto>>> getNotes(
            @RequestParam(required = false) UUID userId,
            @RequestParam(required = false) String visibility,
            @RequestParam(required = false) String language,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        
        Pageable pageable = PageRequest.of(page, size);
        Page<NoteDto> notes;
        
        if (userId != null) {
            notes = noteService.getUserNotes(userId, pageable);
        } else {
            notes = noteService.getPublicNotes(pageable);
        }
        
        return ResponseEntity.ok(ApiResponse.success(notes));
    }
    
    @GetMapping("/search")
    public ResponseEntity<ApiResponse<Page<NoteDto>>> searchNotes(
            @RequestParam(required = false) String title,
            @RequestParam(required = false) String content,
            @RequestParam(required = false) String visibility,
            @RequestParam(required = false) String language,
            @RequestParam(required = false) UUID userId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        
        Pageable pageable = PageRequest.of(page, size);
        Page<NoteDto> notes;
        
        Note.Visibility visibilityEnum = null;
        if (visibility != null) {
            visibilityEnum = Note.Visibility.valueOf(visibility.toUpperCase());
        }
        
        if (userId != null) {
            notes = noteService.searchUserNotes(userId, title, content, 
                    visibilityEnum, language, pageable);
        } else {
            notes = noteService.searchNotes(title, content, 
                    visibilityEnum, language, pageable);
        }
        
        return ResponseEntity.ok(ApiResponse.success(notes));
    }
    
    @GetMapping("/languages")
    public ResponseEntity<ApiResponse<List<String>>> getAvailableLanguages() {
        List<String> languages = noteService.getAvailableCodeLanguages();
        return ResponseEntity.ok(ApiResponse.success(languages));
    }
}

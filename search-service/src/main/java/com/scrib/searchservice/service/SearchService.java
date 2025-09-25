package com.scrib.searchservice.service;

import com.scrib.common.dto.NoteDto;
import com.scrib.common.dto.SearchRequest;
import com.scrib.searchservice.entity.Note;
import com.scrib.searchservice.repository.NoteRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@Transactional(readOnly = true)
public class SearchService {
    
    @Autowired
    private NoteRepository noteRepository;
    
    @Cacheable(value = "searchResults", key = "#searchRequest.toString()")
    public Page<NoteDto> searchNotes(SearchRequest searchRequest) {
        Pageable pageable = PageRequest.of(searchRequest.getPage(), searchRequest.getSize());
        
        Note.Visibility visibility = searchRequest.getVisibility() != null ? 
                Note.Visibility.valueOf(searchRequest.getVisibility().name()) : null;
        
        Page<Note> notes = noteRepository.searchNotes(
                searchRequest.getQuery(),
                searchRequest.getQuery(), // Search in both title and content
                visibility,
                searchRequest.getLanguage(),
                pageable
        );
        
        return notes.map(this::convertToDto);
    }
    
    @Cacheable(value = "userSearchResults", key = "#userId + '_' + #searchRequest.toString()")
    public Page<NoteDto> searchUserNotes(UUID userId, SearchRequest searchRequest) {
        Pageable pageable = PageRequest.of(searchRequest.getPage(), searchRequest.getSize());
        
        Note.Visibility visibility = searchRequest.getVisibility() != null ? 
                Note.Visibility.valueOf(searchRequest.getVisibility().name()) : null;
        
        Page<Note> notes = noteRepository.searchUserNotes(
                userId,
                searchRequest.getQuery(),
                searchRequest.getQuery(), // Search in both title and content
                visibility,
                searchRequest.getLanguage(),
                pageable
        );
        
        return notes.map(this::convertToDto);
    }
    
    @Cacheable(value = "publicNotes", key = "#page + '_' + #size")
    public Page<NoteDto> getPublicNotes(int page, int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<Note> notes = noteRepository.findPublicNotes(pageable);
        return notes.map(this::convertToDto);
    }
    
    @Cacheable(value = "userNotes", key = "#userId + '_' + #page + '_' + #size")
    public Page<NoteDto> getUserNotes(UUID userId, int page, int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<Note> notes = noteRepository.findByUserId(userId, pageable);
        return notes.map(this::convertToDto);
    }
    
    @Cacheable(value = "codeLanguages")
    public List<String> getAvailableCodeLanguages() {
        return noteRepository.findDistinctCodeLanguages();
    }
    
    @Cacheable(value = "notesByLanguage", key = "#language + '_' + #page + '_' + #size")
    public Page<NoteDto> getNotesByLanguage(String language, int page, int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<Note> notes = noteRepository.findByCodeLanguage(language, pageable);
        return notes.map(this::convertToDto);
    }
    
    private NoteDto convertToDto(Note note) {
        return new NoteDto(
                note.getId(),
                note.getUserId(),
                note.getTitle(),
                note.getContent(),
                NoteDto.Visibility.valueOf(note.getVisibility().name()),
                note.getCodeLanguage(),
                note.getCreatedAt(),
                note.getUpdatedAt(),
                note.getDeletedAt()
        );
    }
}

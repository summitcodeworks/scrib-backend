package com.scrib.noteservice.service;

import com.scrib.common.dto.NoteDto;
import com.scrib.noteservice.entity.Note;
import com.scrib.noteservice.repository.NoteRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
@Transactional
public class NoteService {
    
    @Autowired
    private NoteRepository noteRepository;
    
    public NoteDto createNote(NoteDto noteDto) {
        Note note = new Note(
                noteDto.getUserId(),
                noteDto.getTitle(),
                noteDto.getContent(),
                Note.Visibility.valueOf(noteDto.getVisibility().name()),
                noteDto.getCodeLanguage()
        );
        
        Note savedNote = noteRepository.save(note);
        return convertToDto(savedNote);
    }
    
    @CacheEvict(value = "notes", key = "#id")
    public NoteDto updateNote(UUID id, NoteDto noteDto) {
        Note note = noteRepository.findByIdAndUserId(id, noteDto.getUserId())
                .orElseThrow(() -> new IllegalArgumentException("Note not found or access denied"));
        
        note.setTitle(noteDto.getTitle());
        note.setContent(noteDto.getContent());
        note.setVisibility(Note.Visibility.valueOf(noteDto.getVisibility().name()));
        note.setCodeLanguage(noteDto.getCodeLanguage());
        
        Note updatedNote = noteRepository.save(note);
        return convertToDto(updatedNote);
    }
    
    @CacheEvict(value = "notes", key = "#id")
    public void deleteNote(UUID id, UUID userId) {
        Note note = noteRepository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new IllegalArgumentException("Note not found or access denied"));
        
        note.setDeletedAt(LocalDateTime.now());
        noteRepository.save(note);
    }
    
    @Cacheable(value = "notes", key = "#id")
    public Optional<NoteDto> getNoteById(UUID id) {
        return noteRepository.findByIdAndNotDeleted(id)
                .map(this::convertToDto);
    }
    
    @Cacheable(value = "publicNotes", key = "#id")
    public Optional<NoteDto> getPublicNoteById(UUID id) {
        return noteRepository.findPublicById(id)
                .map(this::convertToDto);
    }
    
    public Optional<NoteDto> getUserNoteById(UUID id, UUID userId) {
        return noteRepository.findByIdAndUserId(id, userId)
                .map(this::convertToDto);
    }
    
    public Page<NoteDto> getPublicNotes(Pageable pageable) {
        return noteRepository.findPublicNotes(pageable)
                .map(this::convertToDto);
    }
    
    public Page<NoteDto> getUserNotes(UUID userId, Pageable pageable) {
        return noteRepository.findByUserId(userId, pageable)
                .map(this::convertToDto);
    }
    
    public Page<NoteDto> searchNotes(String title, String content, 
                                   Note.Visibility visibility, String language, 
                                   Pageable pageable) {
        return noteRepository.searchNotes(title, content, visibility, language, pageable)
                .map(this::convertToDto);
    }
    
    public Page<NoteDto> searchUserNotes(UUID userId, String title, String content,
                                       Note.Visibility visibility, String language,
                                       Pageable pageable) {
        return noteRepository.searchUserNotes(userId, title, content, visibility, language, pageable)
                .map(this::convertToDto);
    }
    
    public List<String> getAvailableCodeLanguages() {
        return noteRepository.findDistinctCodeLanguages();
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

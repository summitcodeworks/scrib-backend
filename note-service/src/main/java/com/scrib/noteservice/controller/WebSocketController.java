package com.scrib.noteservice.controller;

import com.scrib.common.dto.NoteDto;
import com.scrib.noteservice.service.NoteService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.SendTo;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;

import java.util.UUID;

@Controller
public class WebSocketController {
    
    @Autowired
    private NoteService noteService;
    
    @Autowired
    private SimpMessagingTemplate messagingTemplate;
    
    @MessageMapping("/note.save")
    @SendTo("/topic/note.saved")
    public NoteDto saveNote(NoteDto noteDto) {
        try {
            NoteDto savedNote;
            if (noteDto.getId() == null) {
                // Create new note
                savedNote = noteService.createNote(noteDto);
            } else {
                // Update existing note
                savedNote = noteService.updateNote(noteDto.getId(), noteDto);
            }
            
            // Send confirmation to specific user
            messagingTemplate.convertAndSendToUser(
                noteDto.getUserId().toString(), 
                "/queue/note.saved", 
                savedNote
            );
            
            return savedNote;
        } catch (Exception e) {
            // Send error to user
            messagingTemplate.convertAndSendToUser(
                noteDto.getUserId().toString(), 
                "/queue/note.error", 
                "Failed to save note: " + e.getMessage()
            );
            throw e;
        }
    }
    
    @MessageMapping("/note.auto-save")
    public void autoSaveNote(NoteDto noteDto) {
        try {
            if (noteDto.getId() != null) {
                noteService.updateNote(noteDto.getId(), noteDto);
                
                // Send confirmation
                messagingTemplate.convertAndSendToUser(
                    noteDto.getUserId().toString(), 
                    "/queue/note.auto-saved", 
                    "Note auto-saved successfully"
                );
            }
        } catch (Exception e) {
            // Send error to user
            messagingTemplate.convertAndSendToUser(
                noteDto.getUserId().toString(), 
                "/queue/note.error", 
                "Auto-save failed: " + e.getMessage()
            );
        }
    }
}

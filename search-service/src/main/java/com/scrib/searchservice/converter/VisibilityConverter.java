package com.scrib.searchservice.converter;

import com.scrib.searchservice.entity.Note;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

@Converter(autoApply = true)
public class VisibilityConverter implements AttributeConverter<Note.Visibility, String> {
    
    @Override
    public String convertToDatabaseColumn(Note.Visibility attribute) {
        if (attribute == null) {
            return null;
        }
        return attribute.name();
    }
    
    @Override
    public Note.Visibility convertToEntityAttribute(String dbData) {
        if (dbData == null) {
            return null;
        }
        try {
            return Note.Visibility.valueOf(dbData);
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Invalid visibility value: " + dbData, e);
        }
    }
}

package com.scrib.searchservice.repository;

import com.scrib.searchservice.entity.Note;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface NoteRepository extends JpaRepository<Note, UUID> {
    
    @Query("SELECT n FROM Note n WHERE n.visibility = 'PUBLIC' AND n.deletedAt IS NULL")
    Page<Note> findPublicNotes(Pageable pageable);
    
    @Query("SELECT n FROM Note n WHERE n.userId = :userId AND n.deletedAt IS NULL")
    Page<Note> findByUserId(@Param("userId") UUID userId, Pageable pageable);
    
    @Query("SELECT n FROM Note n WHERE n.visibility = :visibility AND n.deletedAt IS NULL")
    Page<Note> findByVisibility(@Param("visibility") Note.Visibility visibility, Pageable pageable);
    
    @Query("SELECT n FROM Note n WHERE n.codeLanguage = :language AND n.deletedAt IS NULL")
    Page<Note> findByCodeLanguage(@Param("language") String language, Pageable pageable);
    
    @Query("SELECT n FROM Note n WHERE " +
           "(:title IS NULL OR LOWER(n.title) LIKE LOWER(CONCAT('%', :title, '%'))) AND " +
           "(:content IS NULL OR LOWER(n.content) LIKE LOWER(CONCAT('%', :content, '%'))) AND " +
           "(:visibility IS NULL OR n.visibility = :visibility) AND " +
           "(:language IS NULL OR n.codeLanguage = :language) AND " +
           "n.deletedAt IS NULL")
    Page<Note> searchNotes(@Param("title") String title, 
                           @Param("content") String content,
                           @Param("visibility") Note.Visibility visibility,
                           @Param("language") String language,
                           Pageable pageable);
    
    @Query("SELECT n FROM Note n WHERE " +
           "n.userId = :userId AND " +
           "(:title IS NULL OR LOWER(n.title) LIKE LOWER(CONCAT('%', :title, '%'))) AND " +
           "(:content IS NULL OR LOWER(n.content) LIKE LOWER(CONCAT('%', :content, '%'))) AND " +
           "(:visibility IS NULL OR n.visibility = :visibility) AND " +
           "(:language IS NULL OR n.codeLanguage = :language) AND " +
           "n.deletedAt IS NULL")
    Page<Note> searchUserNotes(@Param("userId") UUID userId,
                               @Param("title") String title, 
                               @Param("content") String content,
                               @Param("visibility") Note.Visibility visibility,
                               @Param("language") String language,
                               Pageable pageable);
    
    @Query("SELECT DISTINCT n.codeLanguage FROM Note n WHERE n.codeLanguage IS NOT NULL AND n.deletedAt IS NULL")
    List<String> findDistinctCodeLanguages();
}

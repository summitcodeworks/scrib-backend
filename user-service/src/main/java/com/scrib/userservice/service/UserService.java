package com.scrib.userservice.service;

import com.scrib.common.dto.UserDto;
import com.scrib.userservice.entity.User;
import com.scrib.userservice.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;

@Service
@Transactional
public class UserService {
    
    @Autowired
    private UserRepository userRepository;
    
    public UserDto createUser(String username) {
        if (userRepository.existsByUsername(username)) {
            throw new IllegalArgumentException("Username already exists: " + username);
        }
        
        User user = new User(username);
        user.setLastActivityAt(LocalDateTime.now());
        User savedUser = userRepository.save(user);
        
        return convertToDto(savedUser);
    }
    
    public boolean usernameExists(String username) {
        return userRepository.existsByUsername(username);
    }
    
    public Optional<UserDto> findByUsername(String username) {
        return userRepository.findByUsername(username)
                .map(this::convertToDto);
    }
    
    public void updateLastActivity(String username) {
        userRepository.findByUsername(username).ifPresent(user -> {
            user.setLastActivityAt(LocalDateTime.now());
            userRepository.save(user);
        });
    }
    
    private UserDto convertToDto(User user) {
        return new UserDto(
                user.getId(),
                user.getUsername(),
                user.getCreatedAt(),
                user.getLastActivityAt()
        );
    }
}

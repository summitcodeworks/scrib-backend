# Scrib Backend API Documentation

## Table of Contents
1. [Overview](#overview)
2. [Authentication](#authentication)
3. [User Service APIs](#user-service-apis)
4. [Note Service APIs](#note-service-apis)
5. [Search Service APIs](#search-service-apis)
6. [WebSocket APIs](#websocket-apis)
7. [Error Responses](#error-responses)
8. [Rate Limiting](#rate-limiting)
9. [Examples](#examples)

## Overview

The Scrib Backend API provides a comprehensive note-taking platform with real-time collaboration features. The API is built using Spring Boot microservices architecture with the following services:

- **Gateway Service**: Port 9200 (Main entry point)
- **User Service**: Port 9201
- **Note Service**: Port 9202
- **Search Service**: Port 9203

**Base URLs:**
- Gateway: `http://localhost:9200`
- User Service: `http://localhost:9201`
- Note Service: `http://localhost:9202`
- Search Service: `http://localhost:9203`

## Authentication

Scrib uses a simple username-based authentication system. No passwords are required - users are identified by unique usernames only.

## User Service APIs

### 1. Create User

**Endpoint:** `POST /api/users`

**Description:** Creates a new user with a unique username.

**Request Body:**
```json
{
  "username": "string"
}
```

**Request Validation:**
- `username`: Required, 3-50 characters, alphanumeric and underscores only

**Success Response (201 Created):**
```json
{
  "success": true,
  "message": "User created successfully",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "username": "john_doe",
    "createdAt": "2024-01-15T10:30:00",
    "lastActivityAt": "2024-01-15T10:30:00"
  },
  "timestamp": "2024-01-15T10:30:00"
}
```

**Error Responses:**
- **400 Bad Request**: Username validation failed
- **409 Conflict**: Username already exists

### 2. Check Username Availability

**Endpoint:** `GET /api/users/{username}/exists`

**Description:** Checks if a username is available for registration.

**Path Parameters:**
- `username`: The username to check (3-50 characters)

**Success Response (200 OK):**
```json
{
  "success": true,
  "data": true,
  "timestamp": "2024-01-15T10:30:00"
}
```

**Error Responses:**
- **400 Bad Request**: Invalid username format
- **404 Not Found**: Username not found

### 3. Get User by Username

**Endpoint:** `GET /api/users/{username}`

**Description:** Retrieves user information by username.

**Path Parameters:**
- `username`: The username to retrieve

**Success Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "username": "john_doe",
    "createdAt": "2024-01-15T10:30:00",
    "lastActivityAt": "2024-01-15T10:30:00"
  },
  "timestamp": "2024-01-15T10:30:00"
}
```

**Error Responses:**
- **404 Not Found**: User not found

### 4. Update User Activity

**Endpoint:** `PUT /api/users/{username}/activity`

**Description:** Updates the last activity timestamp for a user.

**Path Parameters:**
- `username`: The username to update

**Success Response (200 OK):**
```json
{
  "success": true,
  "message": "Activity updated successfully",
  "timestamp": "2024-01-15T10:30:00"
}
```

**Error Responses:**
- **404 Not Found**: User not found

## Note Service APIs

### 1. Create Note

**Endpoint:** `POST /api/notes`

**Description:** Creates a new note with rich text and code formatting.

**Request Body:**
```json
{
  "userId": "550e8400-e29b-41d4-a716-446655440000",
  "title": "My First Note",
  "content": "<p>This is a <strong>rich text</strong> note with <code>inline code</code>.</p><pre><code class=\"language-javascript\">function hello() {\n  console.log('Hello World!');\n}</code></pre>",
  "visibility": "PRIVATE",
  "codeLanguage": "javascript"
}
```

**Request Validation:**
- `userId`: Required, valid UUID
- `title`: Optional, max 255 characters
- `content`: Optional, max 10MB
- `visibility`: Required, "PUBLIC" or "PRIVATE"
- `codeLanguage`: Optional, max 50 characters

**Success Response (201 Created):**
```json
{
  "success": true,
  "message": "Note created successfully",
  "data": {
    "id": "660e8400-e29b-41d4-a716-446655440001",
    "userId": "550e8400-e29b-41d4-a716-446655440000",
    "title": "My First Note",
    "content": "<p>This is a <strong>rich text</strong> note with <code>inline code</code>.</p><pre><code class=\"language-javascript\">function hello() {\n  console.log('Hello World!');\n}</code></pre>",
    "visibility": "PRIVATE",
    "codeLanguage": "javascript",
    "createdAt": "2024-01-15T10:30:00",
    "updatedAt": "2024-01-15T10:30:00",
    "deletedAt": null
  },
  "timestamp": "2024-01-15T10:30:00"
}
```

**Error Responses:**
- **400 Bad Request**: Validation failed
- **404 Not Found**: User not found

### 2. Update Note

**Endpoint:** `PUT /api/notes/{id}`

**Description:** Updates an existing note. Supports real-time saving via WebSocket.

**Path Parameters:**
- `id`: Note UUID

**Request Body:**
```json
{
  "userId": "550e8400-e29b-41d4-a716-446655440000",
  "title": "Updated Note Title",
  "content": "<p>Updated <em>content</em> with <strong>formatting</strong>.</p>",
  "visibility": "PUBLIC",
  "codeLanguage": "python"
}
```

**Success Response (200 OK):**
```json
{
  "success": true,
  "message": "Note updated successfully",
  "data": {
    "id": "660e8400-e29b-41d4-a716-446655440001",
    "userId": "550e8400-e29b-41d4-a716-446655440000",
    "title": "Updated Note Title",
    "content": "<p>Updated <em>content</em> with <strong>formatting</strong>.</p>",
    "visibility": "PUBLIC",
    "codeLanguage": "python",
    "createdAt": "2024-01-15T10:30:00",
    "updatedAt": "2024-01-15T10:35:00",
    "deletedAt": null
  },
  "timestamp": "2024-01-15T10:35:00"
}
```

**Error Responses:**
- **400 Bad Request**: Validation failed or access denied
- **404 Not Found**: Note not found

### 3. Delete Note

**Endpoint:** `DELETE /api/notes/{id}?userId={userId}`

**Description:** Soft deletes a note (marks as deleted but preserves data).

**Path Parameters:**
- `id`: Note UUID

**Query Parameters:**
- `userId`: User UUID (required for authorization)

**Success Response (200 OK):**
```json
{
  "success": true,
  "message": "Note deleted successfully",
  "timestamp": "2024-01-15T10:35:00"
}
```

**Error Responses:**
- **400 Bad Request**: Missing userId parameter
- **404 Not Found**: Note not found or access denied

### 4. Get Note by ID

**Endpoint:** `GET /api/notes/{id}?userId={userId}`

**Description:** Retrieves a specific note. Public notes are accessible without userId.

**Path Parameters:**
- `id`: Note UUID

**Query Parameters:**
- `userId`: User UUID (optional, required for private notes)

**Success Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "id": "660e8400-e29b-41d4-a716-446655440001",
    "userId": "550e8400-e29b-41d4-a716-446655440000",
    "title": "My First Note",
    "content": "<p>This is a <strong>rich text</strong> note.</p>",
    "visibility": "PUBLIC",
    "codeLanguage": "javascript",
    "createdAt": "2024-01-15T10:30:00",
    "updatedAt": "2024-01-15T10:30:00",
    "deletedAt": null
  },
  "timestamp": "2024-01-15T10:30:00"
}
```

**Error Responses:**
- **404 Not Found**: Note not found or access denied

### 5. List Notes

**Endpoint:** `GET /api/notes`

**Description:** Lists notes with filtering options.

**Query Parameters:**
- `userId`: User UUID (optional, filters by user)
- `visibility`: "PUBLIC" or "PRIVATE" (optional)
- `language`: Code language filter (optional)
- `page`: Page number (default: 0)
- `size`: Page size (default: 20, max: 100)

**Success Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "content": [
      {
        "id": "660e8400-e29b-41d4-a716-446655440001",
        "userId": "550e8400-e29b-41d4-a716-446655440000",
        "title": "My First Note",
        "content": "<p>This is a <strong>rich text</strong> note.</p>",
        "visibility": "PUBLIC",
        "codeLanguage": "javascript",
        "createdAt": "2024-01-15T10:30:00",
        "updatedAt": "2024-01-15T10:30:00",
        "deletedAt": null
      }
    ],
    "pageable": {
      "sort": {
        "sorted": false,
        "unsorted": true
      },
      "pageNumber": 0,
      "pageSize": 20,
      "offset": 0,
      "paged": true,
      "unpaged": false
    },
    "totalElements": 1,
    "totalPages": 1,
    "last": true,
    "first": true,
    "numberOfElements": 1,
    "size": 20,
    "number": 0,
    "sort": {
      "sorted": false,
      "unsorted": true
    }
  },
  "timestamp": "2024-01-15T10:30:00"
}
```

### 6. Search Notes

**Endpoint:** `GET /api/notes/search`

**Description:** Advanced search with multiple filters.

**Query Parameters:**
- `title`: Search in note titles (optional)
- `content`: Search in note content (optional)
- `visibility`: "PUBLIC" or "PRIVATE" (optional)
- `language`: Code language filter (optional)
- `userId`: User UUID (optional, for user-specific search)
- `page`: Page number (default: 0)
- `size`: Page size (default: 20, max: 100)

**Success Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "content": [
      {
        "id": "660e8400-e29b-41d4-a716-446655440001",
        "userId": "550e8400-e29b-41d4-a716-446655440000",
        "title": "JavaScript Tutorial",
        "content": "<p>Learn <strong>JavaScript</strong> basics.</p>",
        "visibility": "PUBLIC",
        "codeLanguage": "javascript",
        "createdAt": "2024-01-15T10:30:00",
        "updatedAt": "2024-01-15T10:30:00",
        "deletedAt": null
      }
    ],
    "pageable": {
      "sort": {
        "sorted": false,
        "unsorted": true
      },
      "pageNumber": 0,
      "pageSize": 20,
      "offset": 0,
      "paged": true,
      "unpaged": false
    },
    "totalElements": 1,
    "totalPages": 1,
    "last": true,
    "first": true,
    "numberOfElements": 1,
    "size": 20,
    "number": 0,
    "sort": {
      "sorted": false,
      "unsorted": true
    }
  },
  "timestamp": "2024-01-15T10:30:00"
}
```

### 7. Get Available Code Languages

**Endpoint:** `GET /api/notes/languages`

**Description:** Returns list of available programming languages used in notes.

**Success Response (200 OK):**
```json
{
  "success": true,
  "data": [
    "javascript",
    "python",
    "java",
    "html",
    "css",
    "sql"
  ],
  "timestamp": "2024-01-15T10:30:00"
}
```

## Search Service APIs

### 1. Search Notes

**Endpoint:** `GET /api/search/notes`

**Description:** Advanced search functionality with full-text search capabilities.

**Query Parameters:**
- `query`: Search query (optional, max 100 characters)
- `visibility`: "PUBLIC" or "PRIVATE" (optional)
- `language`: Code language filter (optional)
- `username`: Username filter (optional)
- `page`: Page number (default: 0)
- `size`: Page size (default: 20, max: 100)

**Success Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "content": [
      {
        "id": "660e8400-e29b-41d4-a716-446655440001",
        "userId": "550e8400-e29b-41d4-a716-446655440000",
        "title": "JavaScript Tutorial",
        "content": "<p>Learn <strong>JavaScript</strong> basics.</p>",
        "visibility": "PUBLIC",
        "codeLanguage": "javascript",
        "createdAt": "2024-01-15T10:30:00",
        "updatedAt": "2024-01-15T10:30:00",
        "deletedAt": null
      }
    ],
    "pageable": {
      "sort": {
        "sorted": false,
        "unsorted": true
      },
      "pageNumber": 0,
      "pageSize": 20,
      "offset": 0,
      "paged": true,
      "unpaged": false
    },
    "totalElements": 1,
    "totalPages": 1,
    "last": true,
    "first": true,
    "numberOfElements": 1,
    "size": 20,
    "number": 0,
    "sort": {
      "sorted": false,
      "unsorted": true
    }
  },
  "timestamp": "2024-01-15T10:30:00"
}
```

### 2. Search User Notes

**Endpoint:** `GET /api/search/notes/user/{userId}`

**Description:** Search notes belonging to a specific user.

**Path Parameters:**
- `userId`: User UUID

**Query Parameters:**
- `query`: Search query (optional)
- `visibility`: "PUBLIC" or "PRIVATE" (optional)
- `language`: Code language filter (optional)
- `page`: Page number (default: 0)
- `size`: Page size (default: 20, max: 100)

**Success Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "content": [
      {
        "id": "660e8400-e29b-41d4-a716-446655440001",
        "userId": "550e8400-e29b-41d4-a716-446655440000",
        "title": "My Private Note",
        "content": "<p>This is a <strong>private</strong> note.</p>",
        "visibility": "PRIVATE",
        "codeLanguage": "python",
        "createdAt": "2024-01-15T10:30:00",
        "updatedAt": "2024-01-15T10:30:00",
        "deletedAt": null
      }
    ],
    "pageable": {
      "sort": {
        "sorted": false,
        "unsorted": true
      },
      "pageNumber": 0,
      "pageSize": 20,
      "offset": 0,
      "paged": true,
      "unpaged": false
    },
    "totalElements": 1,
    "totalPages": 1,
    "last": true,
    "first": true,
    "numberOfElements": 1,
    "size": 20,
    "number": 0,
    "sort": {
      "sorted": false,
      "unsorted": true
    }
  },
  "timestamp": "2024-01-15T10:30:00"
}
```

### 3. Get Public Notes

**Endpoint:** `GET /api/search/notes/public`

**Description:** Retrieves all public notes.

**Query Parameters:**
- `page`: Page number (default: 0)
- `size`: Page size (default: 20, max: 100)

**Success Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "content": [
      {
        "id": "660e8400-e29b-41d4-a716-446655440001",
        "userId": "550e8400-e29b-41d4-a716-446655440000",
        "title": "Public JavaScript Tutorial",
        "content": "<p>Learn <strong>JavaScript</strong> basics.</p>",
        "visibility": "PUBLIC",
        "codeLanguage": "javascript",
        "createdAt": "2024-01-15T10:30:00",
        "updatedAt": "2024-01-15T10:30:00",
        "deletedAt": null
      }
    ],
    "pageable": {
      "sort": {
        "sorted": false,
        "unsorted": true
      },
      "pageNumber": 0,
      "pageSize": 20,
      "offset": 0,
      "paged": true,
      "unpaged": false
    },
    "totalElements": 1,
    "totalPages": 1,
    "last": true,
    "first": true,
    "numberOfElements": 1,
    "size": 20,
    "number": 0,
    "sort": {
      "sorted": false,
      "unsorted": true
    }
  },
  "timestamp": "2024-01-15T10:30:00"
}
```

### 4. Get User Notes

**Endpoint:** `GET /api/search/notes/user/{userId}/all`

**Description:** Retrieves all notes belonging to a specific user.

**Path Parameters:**
- `userId`: User UUID

**Query Parameters:**
- `page`: Page number (default: 0)
- `size`: Page size (default: 20, max: 100)

**Success Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "content": [
      {
        "id": "660e8400-e29b-41d4-a716-446655440001",
        "userId": "550e8400-e29b-41d4-a716-446655440000",
        "title": "My Note",
        "content": "<p>This is my note.</p>",
        "visibility": "PRIVATE",
        "codeLanguage": "python",
        "createdAt": "2024-01-15T10:30:00",
        "updatedAt": "2024-01-15T10:30:00",
        "deletedAt": null
      }
    ],
    "pageable": {
      "sort": {
        "sorted": false,
        "unsorted": true
      },
      "pageNumber": 0,
      "pageSize": 20,
      "offset": 0,
      "paged": true,
      "unpaged": false
    },
    "totalElements": 1,
    "totalPages": 1,
    "last": true,
    "first": true,
    "numberOfElements": 1,
    "size": 20,
    "number": 0,
    "sort": {
      "sorted": false,
      "unsorted": true
    }
  },
  "timestamp": "2024-01-15T10:30:00"
}
```

### 5. Get Notes by Language

**Endpoint:** `GET /api/search/notes/language/{language}`

**Description:** Retrieves notes containing code in a specific programming language.

**Path Parameters:**
- `language`: Programming language (e.g., "javascript", "python", "java")

**Query Parameters:**
- `page`: Page number (default: 0)
- `size`: Page size (default: 20, max: 100)

**Success Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "content": [
      {
        "id": "660e8400-e29b-41d4-a716-446655440001",
        "userId": "550e8400-e29b-41d4-a716-446655440000",
        "title": "JavaScript Tutorial",
        "content": "<p>Learn <strong>JavaScript</strong> basics.</p>",
        "visibility": "PUBLIC",
        "codeLanguage": "javascript",
        "createdAt": "2024-01-15T10:30:00",
        "updatedAt": "2024-01-15T10:30:00",
        "deletedAt": null
      }
    ],
    "pageable": {
      "sort": {
        "sorted": false,
        "unsorted": true
      },
      "pageNumber": 0,
      "pageSize": 20,
      "offset": 0,
      "paged": true,
      "unpaged": false
    },
    "totalElements": 1,
    "totalPages": 1,
    "last": true,
    "first": true,
    "numberOfElements": 1,
    "size": 20,
    "number": 0,
    "sort": {
      "sorted": false,
      "unsorted": true
    }
  },
  "timestamp": "2024-01-15T10:30:00"
}
```

### 6. Get Available Languages

**Endpoint:** `GET /api/search/languages`

**Description:** Returns list of all programming languages used in notes.

**Success Response (200 OK):**
```json
{
  "success": true,
  "data": [
    "javascript",
    "python",
    "java",
    "html",
    "css",
    "sql",
    "typescript",
    "go",
    "rust"
  ],
  "timestamp": "2024-01-15T10:30:00"
}
```

## WebSocket APIs

### Connection

**Endpoint:** `ws://localhost:9200/ws`

**Description:** Establishes WebSocket connection for real-time note saving and collaboration.

**Connection Headers:**
```
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Key: [base64-encoded-key]
Sec-WebSocket-Version: 13
```

**Supported Subprotocols:**
- STOMP (recommended)
- SockJS fallback

### 1. Save Note

**Destination:** `/app/note.save`

**Description:** Saves note changes in real-time.

**Message Format:**
```json
{
  "id": "660e8400-e29b-41d4-a716-446655440001",
  "userId": "550e8400-e29b-41d4-a716-446655440000",
  "title": "My Note",
  "content": "<p>Updated <strong>content</strong>.</p>",
  "visibility": "PRIVATE",
  "codeLanguage": "javascript"
}
```

**Success Response:**
**Destination:** `/topic/note.saved`

```json
{
  "id": "660e8400-e29b-41d4-a716-446655440001",
  "userId": "550e8400-e29b-41d4-a716-446655440000",
  "title": "My Note",
  "content": "<p>Updated <strong>content</strong>.</p>",
  "visibility": "PRIVATE",
  "codeLanguage": "javascript",
  "createdAt": "2024-01-15T10:30:00",
  "updatedAt": "2024-01-15T10:35:00",
  "deletedAt": null
}
```

**User-specific Confirmation:**
**Destination:** `/queue/note.saved`

```json
{
  "id": "660e8400-e29b-41d4-a716-446655440001",
  "userId": "550e8400-e29b-41d4-a716-446655440000",
  "title": "My Note",
  "content": "<p>Updated <strong>content</strong>.</p>",
  "visibility": "PRIVATE",
  "codeLanguage": "javascript",
  "createdAt": "2024-01-15T10:30:00",
  "updatedAt": "2024-01-15T10:35:00",
  "deletedAt": null
}
```

### 2. Auto-save Note

**Destination:** `/app/note.auto-save`

**Description:** Auto-saves note changes with debouncing (500ms delay).

**Message Format:**
```json
{
  "id": "660e8400-e29b-41d4-a716-446655440001",
  "userId": "550e8400-e29b-41d4-a716-446655440000",
  "title": "My Note",
  "content": "<p>Auto-saved <strong>content</strong>.</p>",
  "visibility": "PRIVATE",
  "codeLanguage": "javascript"
}
```

**Success Response:**
**Destination:** `/queue/note.auto-saved`

```json
"Note auto-saved successfully"
```

### 3. Error Handling

**Error Response:**
**Destination:** `/queue/note.error`

```json
"Failed to save note: Validation error - Content exceeds maximum size"
```

**Common Error Messages:**
- "Failed to save note: Note not found"
- "Failed to save note: Access denied"
- "Failed to save note: Validation error - Invalid content format"
- "Auto-save failed: Database connection error"

## Error Responses

### HTTP Status Codes

#### 400 Bad Request
```json
{
  "success": false,
  "message": "Validation failed",
  "data": {
    "username": "Username must be between 3 and 50 characters",
    "content": "Content must not exceed 10MB"
  },
  "timestamp": "2024-01-15T10:30:00"
}
```

#### 401 Unauthorized
```json
{
  "success": false,
  "message": "Authentication required",
  "timestamp": "2024-01-15T10:30:00"
}
```

#### 403 Forbidden
```json
{
  "success": false,
  "message": "Access denied - insufficient permissions",
  "timestamp": "2024-01-15T10:30:00"
}
```

#### 404 Not Found
```json
{
  "success": false,
  "message": "Resource not found",
  "timestamp": "2024-01-15T10:30:00"
}
```

#### 409 Conflict
```json
{
  "success": false,
  "message": "Username already exists",
  "timestamp": "2024-01-15T10:30:00"
}
```

#### 413 Payload Too Large
```json
{
  "success": false,
  "message": "Content size exceeds maximum limit of 10MB",
  "timestamp": "2024-01-15T10:30:00"
}
```

#### 422 Unprocessable Entity
```json
{
  "success": false,
  "message": "Invalid data format",
  "data": {
    "field": "Invalid JSON format in content field"
  },
  "timestamp": "2024-01-15T10:30:00"
}
```

#### 429 Too Many Requests
```json
{
  "success": false,
  "message": "Rate limit exceeded. Please try again later.",
  "timestamp": "2024-01-15T10:30:00"
}
```

#### 500 Internal Server Error
```json
{
  "success": false,
  "message": "An unexpected error occurred",
  "timestamp": "2024-01-15T10:30:00"
}
```

#### 503 Service Unavailable
```json
{
  "success": false,
  "message": "Service temporarily unavailable",
  "timestamp": "2024-01-15T10:30:00"
}
```

### Validation Errors

#### Username Validation
- **Required**: "Username is required"
- **Length**: "Username must be between 3 and 50 characters"
- **Format**: "Username can only contain alphanumeric characters and underscores"
- **Uniqueness**: "Username already exists"

#### Note Content Validation
- **Size**: "Content must not exceed 10MB"
- **Format**: "Invalid content format"
- **XSS Protection**: "Content contains potentially harmful scripts"

#### User ID Validation
- **Required**: "User ID is required"
- **Format**: "Invalid UUID format"
- **Existence**: "User not found"

#### Visibility Validation
- **Required**: "Visibility is required"
- **Values**: "Visibility must be either PUBLIC or PRIVATE"

#### Code Language Validation
- **Length**: "Language must not exceed 50 characters"
- **Format**: "Invalid language format"

### Database Errors

#### Connection Errors
- **Timeout**: "Database connection timeout"
- **Unavailable**: "Database service unavailable"
- **Authentication**: "Database authentication failed"

#### Constraint Violations
- **Unique Constraint**: "Username already exists"
- **Foreign Key**: "Referenced user does not exist"
- **Check Constraint**: "Invalid data violates database constraints"

#### Transaction Errors
- **Deadlock**: "Database deadlock detected"
- **Rollback**: "Transaction rolled back due to error"
- **Lock Timeout**: "Database lock timeout"

### WebSocket Errors

#### Connection Errors
- **Connection Failed**: "WebSocket connection failed"
- **Authentication Failed**: "WebSocket authentication failed"
- **Protocol Error**: "Invalid WebSocket protocol"

#### Message Errors
- **Invalid Format**: "Invalid message format"
- **Missing Fields**: "Required fields missing"
- **Size Exceeded**: "Message size exceeds limit"

#### Real-time Errors
- **Save Failed**: "Failed to save note changes"
- **Sync Failed**: "Failed to synchronize changes"
- **Permission Denied**: "Permission denied for real-time updates"

## Rate Limiting

### Limits
- **Per IP**: 100 requests per minute
- **Per User**: 1000 requests per hour
- **WebSocket**: 50 messages per minute per connection

### Headers
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1642248600
```

### Rate Limit Exceeded Response
```json
{
  "success": false,
  "message": "Rate limit exceeded. Please try again later.",
  "timestamp": "2024-01-15T10:30:00"
}
```

## Examples

### Complete User Registration Flow

1. **Check Username Availability**
```bash
curl -X GET "http://localhost:9200/api/users/john_doe/exists"
```

2. **Create User**
```bash
curl -X POST "http://localhost:9200/api/users" \
  -H "Content-Type: application/json" \
  -d '{"username": "john_doe"}'
```

3. **Create Note**
```bash
curl -X POST "http://localhost:9200/api/notes" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "550e8400-e29b-41d4-a716-446655440000",
    "title": "My First Note",
    "content": "<p>Hello <strong>World</strong>!</p>",
    "visibility": "PRIVATE"
  }'
```

### WebSocket Real-time Saving

```javascript
// Connect to WebSocket
const socket = new SockJS('http://localhost:9200/ws');
const stompClient = Stomp.over(socket);

stompClient.connect({}, function(frame) {
    console.log('Connected: ' + frame);
    
    // Subscribe to user-specific updates
    stompClient.subscribe('/user/550e8400-e29b-41d4-a716-446655440000/queue/note.saved', function(message) {
        const note = JSON.parse(message.body);
        console.log('Note saved:', note);
    });
    
    // Subscribe to auto-save confirmations
    stompClient.subscribe('/user/550e8400-e29b-41d4-a716-446655440000/queue/note.auto-saved', function(message) {
        console.log('Auto-saved:', message.body);
    });
    
    // Subscribe to errors
    stompClient.subscribe('/user/550e8400-e29b-41d4-a716-446655440000/queue/note.error', function(message) {
        console.error('Error:', message.body);
    });
});

// Save note changes
function saveNote(noteData) {
    stompClient.send('/app/note.save', {}, JSON.stringify(noteData));
}

// Auto-save note changes
function autoSaveNote(noteData) {
    stompClient.send('/app/note.auto-save', {}, JSON.stringify(noteData));
}
```

### Advanced Search Example

```bash
curl -X GET "http://localhost:9200/api/search/notes?query=javascript&visibility=PUBLIC&language=javascript&page=0&size=10"
```

### Error Handling Example

```javascript
// Handle API errors
fetch('http://localhost:9200/api/notes', {
    method: 'POST',
    headers: {
        'Content-Type': 'application/json'
    },
    body: JSON.stringify(noteData)
})
.then(response => {
    if (!response.ok) {
        return response.json().then(error => {
            throw new Error(error.message);
        });
    }
    return response.json();
})
.then(data => {
    console.log('Success:', data);
})
.catch(error => {
    console.error('Error:', error.message);
});
```

---

This comprehensive API documentation covers all endpoints, WebSocket connections, request/response formats, and error scenarios for the Scrib Backend API. The API supports real-time collaboration, rich text formatting, code snippets, and advanced search capabilities.

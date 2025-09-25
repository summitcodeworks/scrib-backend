-- Scrib Backend Sample Data
-- This script populates the database with sample data for testing and development

-- ==============================================
-- SAMPLE USERS
-- ==============================================

-- Insert sample users
INSERT INTO users (id, username, created_at, last_activity_at) VALUES
    ('550e8400-e29b-41d4-a716-446655440000', 'john_doe', '2024-01-15T10:00:00', '2024-01-15T10:30:00'),
    ('550e8400-e29b-41d4-a716-446655440001', 'jane_smith', '2024-01-15T10:05:00', '2024-01-15T10:25:00'),
    ('550e8400-e29b-41d4-a716-446655440002', 'alex_dev', '2024-01-15T10:10:00', '2024-01-15T10:20:00'),
    ('550e8400-e29b-41d4-a716-446655440003', 'sarah_writer', '2024-01-15T10:15:00', '2024-01-15T10:35:00'),
    ('550e8400-e29b-41d4-a716-446655440004', 'mike_coder', '2024-01-15T10:20:00', '2024-01-15T10:40:00')
ON CONFLICT (username) DO NOTHING;

-- ==============================================
-- SAMPLE NOTES - JAVASCRIPT
-- ==============================================

INSERT INTO notes (id, user_id, title, content, visibility, code_language, created_at, updated_at) VALUES
    ('660e8400-e29b-41d4-a716-446655440000', '550e8400-e29b-41d4-a716-446655440000', 
     'JavaScript Fundamentals', 
     '<h2>JavaScript Basics</h2><p>JavaScript is a <strong>versatile</strong> programming language used for web development.</p><h3>Variables</h3><pre><code class="language-javascript">// Variable declarations\nlet name = "John";\nconst age = 25;\nvar city = "New York";</code></pre><h3>Functions</h3><pre><code class="language-javascript">function greet(name) {\n  return `Hello, ${name}!`;\n}\n\n// Arrow function\nconst greetArrow = (name) => `Hello, ${name}!`;</code></pre>', 
     'PUBLIC', 'javascript', '2024-01-15T10:15:00', '2024-01-15T10:15:00'),
    
    ('660e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440000', 
     'React Hooks Tutorial', 
     '<h2>React Hooks</h2><p>React Hooks allow you to use state and other React features in functional components.</p><h3>useState Hook</h3><pre><code class="language-javascript">import React, { useState } from ''react'';\n\nfunction Counter() {\n  const [count, setCount] = useState(0);\n  \n  return (\n    <div>\n      <p>Count: {count}</p>\n      <button onClick={() => setCount(count + 1)}>\n        Increment\n      </button>\n    </div>\n  );\n}</code></pre>', 
     'PUBLIC', 'javascript', '2024-01-15T10:20:00', '2024-01-15T10:20:00'),
    
    ('660e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440000', 
     'My Private JavaScript Notes', 
     '<p>These are my <em>private</em> JavaScript learning notes.</p><ul><li>Advanced closures</li><li>Prototype inheritance</li><li>Async/await patterns</li></ul>', 
     'PRIVATE', 'javascript', '2024-01-15T10:25:00', '2024-01-15T10:25:00');

-- ==============================================
-- SAMPLE NOTES - PYTHON
-- ==============================================

INSERT INTO notes (id, user_id, title, content, visibility, code_language, created_at, updated_at) VALUES
    ('660e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440001', 
     'Python Data Analysis', 
     '<h2>Data Analysis with Python</h2><p>Python is excellent for <strong>data analysis</strong> with libraries like pandas and numpy.</p><h3>Pandas Basics</h3><pre><code class="language-python">import pandas as pd\nimport numpy as np\n\n# Create a DataFrame\ndata = {\n    ''Name'': [''Alice'', ''Bob'', ''Charlie''],\n    ''Age'': [25, 30, 35],\n    ''City'': [''New York'', ''London'', ''Tokyo'']\n}\ndf = pd.DataFrame(data)\nprint(df.head())</code></pre>', 
     'PUBLIC', 'python', '2024-01-15T10:30:00', '2024-01-15T10:30:00'),
    
    ('660e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440001', 
     'Machine Learning Notes', 
     '<h2>Machine Learning with Python</h2><p>Scikit-learn is a powerful library for machine learning.</p><pre><code class="language-python">from sklearn.model_selection import train_test_split\nfrom sklearn.linear_model import LinearRegression\nfrom sklearn.metrics import mean_squared_error\n\n# Load data\nX, y = load_data()\nX_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2)\n\n# Train model\nmodel = LinearRegression()\nmodel.fit(X_train, y_train)\n\n# Make predictions\npredictions = model.predict(X_test)</code></pre>', 
     'PUBLIC', 'python', '2024-01-15T10:35:00', '2024-01-15T10:35:00');

-- ==============================================
-- SAMPLE NOTES - JAVA
-- ==============================================

INSERT INTO notes (id, user_id, title, content, visibility, code_language, created_at, updated_at) VALUES
    ('660e8400-e29b-41d4-a716-446655440005', '550e8400-e29b-41d4-a716-446655440002', 
     'Java Spring Boot', 
     '<h2>Spring Boot Application</h2><p>Spring Boot makes it easy to create <strong>standalone</strong> Spring applications.</p><h3>Controller Example</h3><pre><code class="language-java">@RestController\n@RequestMapping("/api/users")\npublic class UserController {\n    \n    @Autowired\n    private UserService userService;\n    \n    @GetMapping\n    public ResponseEntity<List<User>> getAllUsers() {\n        List<User> users = userService.findAll();\n        return ResponseEntity.ok(users);\n    }\n    \n    @PostMapping\n    public ResponseEntity<User> createUser(@RequestBody User user) {\n        User savedUser = userService.save(user);\n        return ResponseEntity.status(HttpStatus.CREATED).body(savedUser);\n    }\n}</code></pre>', 
     'PUBLIC', 'java', '2024-01-15T10:40:00', '2024-01-15T10:40:00'),
    
    ('660e8400-e29b-41d4-a716-446655440006', '550e8400-e29b-41d4-a716-446655440002', 
     'Java Design Patterns', 
     '<h2>Common Design Patterns</h2><p>Design patterns are <em>reusable</em> solutions to common problems in software design.</p><h3>Singleton Pattern</h3><pre><code class="language-java">public class Singleton {\n    private static Singleton instance;\n    \n    private Singleton() {}\n    \n    public static Singleton getInstance() {\n        if (instance == null) {\n            instance = new Singleton();\n        }\n        return instance;\n    }\n}</code></pre>', 
     'PRIVATE', 'java', '2024-01-15T10:45:00', '2024-01-15T10:45:00');

-- ==============================================
-- SAMPLE NOTES - HTML/CSS
-- ==============================================

INSERT INTO notes (id, user_id, title, content, visibility, code_language, created_at, updated_at) VALUES
    ('660e8400-e29b-41d4-a716-446655440007', '550e8400-e29b-41d4-a716-446655440003', 
     'CSS Grid Layout', 
     '<h2>CSS Grid Layout</h2><p>CSS Grid is a <strong>two-dimensional</strong> layout system for the web.</p><h3>Basic Grid</h3><pre><code class="language-css">.container {\n  display: grid;\n  grid-template-columns: repeat(3, 1fr);\n  grid-gap: 20px;\n}\n\n.item {\n  background-color: #f0f0f0;\n  padding: 20px;\n  text-align: center;\n}</code></pre>', 
     'PUBLIC', 'css', '2024-01-15T10:50:00', '2024-01-15T10:50:00'),
    
    ('660e8400-e29b-41d4-a716-446655440008', '550e8400-e29b-41d4-a716-446655440003', 
     'HTML5 Semantic Elements', 
     '<h2>HTML5 Semantic Elements</h2><p>Semantic elements provide <em>meaning</em> to the structure of web pages.</p><pre><code class="language-html"><!DOCTYPE html>\n<html>\n<head>\n    <title>Semantic HTML</title>\n</head>\n<body>\n    <header>\n        <h1>Website Title</h1>\n        <nav>\n            <ul>\n                <li><a href="#home">Home</a></li>\n                <li><a href="#about">About</a></li>\n            </ul>\n        </nav>\n    </header>\n    \n    <main>\n        <article>\n            <h2>Article Title</h2>\n            <p>Article content...</p>\n        </article>\n    </main>\n    \n    <footer>\n        <p>&copy; 2024 My Website</p>\n    </footer>\n</body>\n</html></code></pre>', 
     'PUBLIC', 'html', '2024-01-15T10:55:00', '2024-01-15T10:55:00');

-- ==============================================
-- SAMPLE NOTES - SQL
-- ==============================================

INSERT INTO notes (id, user_id, title, content, visibility, code_language, created_at, updated_at) VALUES
    ('660e8400-e29b-41d4-a716-446655440009', '550e8400-e29b-41d4-a716-446655440004', 
     'SQL Queries for Beginners', 
     '<h2>SQL Fundamentals</h2><p>SQL (Structured Query Language) is used to manage and manipulate databases.</p><h3>Basic Queries</h3><pre><code class="language-sql">-- Select all users\nSELECT * FROM users;\n\n-- Select specific columns\nSELECT username, created_at FROM users;\n\n-- Filter with WHERE clause\nSELECT * FROM users WHERE created_at > ''2024-01-01'';\n\n-- Join tables\nSELECT u.username, n.title, n.created_at\nFROM users u\nJOIN notes n ON u.id = n.user_id;</code></pre>', 
     'PUBLIC', 'sql', '2024-01-15T11:00:00', '2024-01-15T11:00:00'),
    
    ('660e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440004', 
     'Database Optimization', 
     '<h2>Database Performance</h2><p>Optimizing database queries is crucial for <strong>performance</strong>.</p><h3>Indexes</h3><pre><code class="language-sql">-- Create index for better performance\nCREATE INDEX idx_users_username ON users(username);\nCREATE INDEX idx_notes_user_id ON notes(user_id);\n\n-- Composite index\nCREATE INDEX idx_notes_visibility_created \nON notes(visibility, created_at DESC);</code></pre>', 
     'PRIVATE', 'sql', '2024-01-15T11:05:00', '2024-01-15T11:05:00');

-- ==============================================
-- SAMPLE NOTES - MIXED CONTENT
-- ==============================================

INSERT INTO notes (id, user_id, title, content, visibility, code_language, created_at, updated_at) VALUES
    ('660e8400-e29b-41d4-a716-446655440011', '550e8400-e29b-41d4-a716-446655440000', 
     'Full-Stack Development', 
     '<h2>Full-Stack Development Guide</h2><p>Building complete web applications requires knowledge of both frontend and backend technologies.</p><h3>Frontend Technologies</h3><ul><li><strong>HTML5</strong> - Structure</li><li><strong>CSS3</strong> - Styling</li><li><strong>JavaScript</strong> - Interactivity</li><li><strong>React</strong> - UI Framework</li></ul><h3>Backend Technologies</h3><ul><li><strong>Node.js</strong> - Runtime</li><li><strong>Express.js</strong> - Web Framework</li><li><strong>PostgreSQL</strong> - Database</li><li><strong>Redis</strong> - Caching</li></ul><h3>API Example</h3><pre><code class="language-javascript">// Express.js API endpoint\napp.get(''/api/notes'', async (req, res) => {\n  try {\n    const notes = await Note.findAll();\n    res.json(notes);\n  } catch (error) {\n    res.status(500).json({ error: error.message });\n  }\n});</code></pre>', 
     'PUBLIC', 'javascript', '2024-01-15T11:10:00', '2024-01-15T11:10:00'),
    
    ('660e8400-e29b-41d4-a716-446655440012', '550e8400-e29b-41d4-a716-446655440001', 
     'My Learning Journey', 
     '<h2>My Programming Journey</h2><p>This note documents my <em>learning journey</em> in programming.</p><h3>Completed Courses</h3><ol><li>JavaScript Fundamentals</li><li>React Development</li><li>Python for Data Science</li><li>Database Design</li></ol><h3>Current Projects</h3><ul><li>Personal Portfolio Website</li><li>E-commerce Application</li><li>Data Analysis Dashboard</li></ul><h3>Goals for 2024</h3><ul><li>Learn Machine Learning</li><li>Contribute to Open Source</li><li>Build a Mobile App</li></ul>', 
     'PRIVATE', NULL, '2024-01-15T11:15:00', '2024-01-15T11:15:00');

-- ==============================================
-- SAMPLE NOTES - TECHNICAL DOCUMENTATION
-- ==============================================

INSERT INTO notes (id, user_id, title, content, visibility, code_language, created_at, updated_at) VALUES
    ('660e8400-e29b-41d4-a716-446655440013', '550e8400-e29b-41d4-a716-446655440002', 
     'Docker Containerization', 
     '<h2>Docker for Developers</h2><p>Docker helps in <strong>containerizing</strong> applications for consistent deployment.</p><h3>Dockerfile Example</h3><pre><code class="language-dockerfile">FROM node:18-alpine\n\nWORKDIR /app\n\nCOPY package*.json ./\nRUN npm install\n\nCOPY . .\n\nEXPOSE 3000\n\nCMD ["npm", "start"]</code></pre><h3>Docker Compose</h3><pre><code class="language-yaml">version: ''3.8''\nservices:\n  app:\n    build: .\n    ports:\n      - "3000:3000"\n  db:\n    image: postgres:15\n    environment:\n      POSTGRES_DB: myapp\n      POSTGRES_USER: user\n      POSTGRES_PASSWORD: password</code></pre>', 
     'PUBLIC', 'dockerfile', '2024-01-15T11:20:00', '2024-01-15T11:20:00'),
    
    ('660e8400-e29b-41d4-a716-446655440014', '550e8400-e29b-41d4-a716-446655440003', 
     'Git Workflow', 
     '<h2>Git Best Practices</h2><p>Effective use of Git is essential for <em>collaborative</em> development.</p><h3>Branching Strategy</h3><pre><code class="language-bash"># Create feature branch\ngit checkout -b feature/new-feature\n\n# Make changes and commit\ngit add .\ngit commit -m "Add new feature"\n\n# Push to remote\ngit push origin feature/new-feature\n\n# Create pull request\ngit checkout main\ngit merge feature/new-feature</code></pre>', 
     'PUBLIC', 'bash', '2024-01-15T11:25:00', '2024-01-15T11:25:00');

-- ==============================================
-- SAMPLE NOTES - DELETED NOTES (FOR TESTING)
-- ==============================================

-- Insert some notes that will be soft deleted for testing
INSERT INTO notes (id, user_id, title, content, visibility, code_language, created_at, updated_at, deleted_at) VALUES
    ('660e8400-e29b-41d4-a716-446655440015', '550e8400-e29b-41d4-a716-446655440000', 
     'Old Note (Deleted)', 
     '<p>This note has been deleted for testing purposes.</p>', 
     'PRIVATE', NULL, '2024-01-01T10:00:00', '2024-01-01T10:00:00', '2024-01-15T10:00:00'),
    
    ('660e8400-e29b-41d4-a716-446655440016', '550e8400-e29b-41d4-a716-446655440001', 
     'Another Deleted Note', 
     '<p>Another deleted note for testing.</p>', 
     'PRIVATE', NULL, '2024-01-02T10:00:00', '2024-01-02T10:00:00', '2024-01-15T10:00:00');

-- ==============================================
-- SAMPLE DATA COMPLETION
-- ==============================================

-- Update user activity timestamps
UPDATE users SET last_activity_at = CURRENT_TIMESTAMP WHERE username = 'john_doe';
UPDATE users SET last_activity_at = CURRENT_TIMESTAMP WHERE username = 'jane_smith';
UPDATE users SET last_activity_at = CURRENT_TIMESTAMP WHERE username = 'alex_dev';
UPDATE users SET last_activity_at = CURRENT_TIMESTAMP WHERE username = 'sarah_writer';
UPDATE users SET last_activity_at = CURRENT_TIMESTAMP WHERE username = 'mike_coder';

-- ==============================================
-- VERIFICATION QUERIES
-- ==============================================

-- Verify sample data insertion
SELECT 
    'Users' as table_name, 
    COUNT(*) as record_count
FROM users
UNION ALL
SELECT 
    'Active Notes' as table_name, 
    COUNT(*) as record_count
FROM notes
WHERE deleted_at IS NULL
UNION ALL
SELECT 
    'Deleted Notes' as table_name, 
    COUNT(*) as record_count
FROM notes
WHERE deleted_at IS NOT NULL;

-- Show notes by language
SELECT 
    code_language,
    COUNT(*) as note_count,
    COUNT(*) FILTER (WHERE visibility = 'PUBLIC') as public_count
FROM notes
WHERE deleted_at IS NULL
GROUP BY code_language
ORDER BY note_count DESC;

-- Show user activity
SELECT 
    u.username,
    COUNT(n.id) as note_count,
    MAX(n.updated_at) as last_note_update
FROM users u
LEFT JOIN notes n ON u.id = n.user_id AND n.deleted_at IS NULL
GROUP BY u.id, u.username
ORDER BY note_count DESC;

-- ==============================================
-- END OF SAMPLE DATA
-- ==============================================

SELECT 'Sample data insertion completed successfully!' as status;

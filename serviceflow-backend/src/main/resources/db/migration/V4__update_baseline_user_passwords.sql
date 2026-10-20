-- V4: Update default test user passwords with valid BCrypt hashes
-- Passwords:
-- admin: Admin@123456
-- dispatcher: Dispatcher@123
-- technician: Technician@123
-- technician2: Technician@123

UPDATE users SET password = '$2a$10$NfaWLX8QGJ.C9k6kDyhhse3SNN2yvzfR9/tClZ4ZRLFQhal7HI89y' WHERE username = 'admin';
UPDATE users SET password = '$2a$10$N0QYLmtZPN/Oao3Up8efLu7iviCGIlBm07U84ii4ctos/uCDZtKUi' WHERE username = 'dispatcher';
UPDATE users SET password = '$2a$10$sl6R5ggHjojTV1pZvBbMLehWrB4HlrMf.NwOqvjAcll.FQ9DuWNjW' WHERE username IN ('technician', 'technician2');

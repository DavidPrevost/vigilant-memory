"""
Validation Utilities
"""
import re


def validate_email(email):
    """Validate email format"""
    if not email:
        return False

    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return re.match(pattern, email) is not None


def validate_uuid(uuid_string):
    """Validate UUID format"""
    if not uuid_string:
        return False

    pattern = r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    return re.match(pattern, uuid_string, re.IGNORECASE) is not None


def validate_password(password):
    """Validate password strength"""
    if not password or len(password) < 8:
        return False

    # At least one uppercase, one lowercase, one digit
    if not re.search(r'[A-Z]', password):
        return False
    if not re.search(r'[a-z]', password):
        return False
    if not re.search(r'\d', password):
        return False

    return True


def validate_phone(phone):
    """Validate phone number format (basic)"""
    if not phone:
        return False

    # Remove common formatting characters
    cleaned = re.sub(r'[\s\-\(\)]', '', phone)

    # Check if it's all digits and reasonable length
    return cleaned.isdigit() and 10 <= len(cleaned) <= 15

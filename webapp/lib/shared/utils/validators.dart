class Validators {
  // Email validator
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // Password validator
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  // Required field validator
  static String? Function(String?) required(String message) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return message;
      }
      return null;
    };
  }

  // Phone number validator (optional)
  static String? phoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    final phoneRegex = RegExp(r'^\+?[\d\s-()]+$');

    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  // Min length validator
  static String? Function(String?) minLength(int length, String fieldName) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return '$fieldName is required';
      }

      if (value.length < length) {
        return '$fieldName must be at least $length characters';
      }

      return null;
    };
  }

  // Max length validator
  static String? Function(String?) maxLength(int length, String fieldName) {
    return (String? value) {
      if (value != null && value.length > length) {
        return '$fieldName must be at most $length characters';
      }

      return null;
    };
  }

  // Number validator
  static String? number(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }

    return null;
  }

  // Integer validator
  static String? integer(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    if (int.tryParse(value) == null) {
      return 'Please enter a valid integer';
    }

    return null;
  }

  // Range validator
  static String? Function(String?) range(double min, double max, String fieldName) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return '$fieldName is required';
      }

      final numValue = double.tryParse(value);
      if (numValue == null) {
        return 'Please enter a valid number';
      }

      if (numValue < min || numValue > max) {
        return '$fieldName must be between $min and $max';
      }

      return null;
    };
  }

  // URL validator
  static String? url(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );

    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL';
    }

    return null;
  }

  // Match validator (for password confirmation)
  static String? Function(String?) match(String otherValue, String fieldName) {
    return (String? value) {
      if (value != otherValue) {
        return '$fieldName does not match';
      }
      return null;
    };
  }

  // Custom validator combiner
  static String? Function(String?) combine(List<String? Function(String?)> validators) {
    return (String? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}

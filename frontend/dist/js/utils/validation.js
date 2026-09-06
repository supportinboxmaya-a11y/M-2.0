// Maya 2.0 ULTRA - Validation Utilities

export const validators = {
  required: (value) => {
    if (value === null || value === undefined || value === '') {
      return 'This field is required';
    }
    return null;
  },
  
  email: (value) => {
    if (!value) return null;
    const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!regex.test(value)) return 'Invalid email address';
    return null;
  },
  
  url: (value) => {
    if (!value) return null;
    try {
      new URL(value);
      return null;
    } catch {
      return 'Invalid URL';
    }
  },
  
  minLength: (min) => (value) => {
    if (!value) return null;
    if (value.length < min) return `Must be at least ${min} characters`;
    return null;
  },
  
  maxLength: (max) => (value) => {
    if (!value) return null;
    if (value.length > max) return `Must be no more than ${max} characters`;
    return null;
  },
  
  pattern: (regex, message) => (value) => {
    if (!value) return null;
    if (!regex.test(value)) return message || 'Invalid format';
    return null;
  },
  
  numeric: (value) => {
    if (!value) return null;
    if (isNaN(Number(value))) return 'Must be a number';
    return null;
  },
  
  integer: (value) => {
    if (!value) return null;
    if (!Number.isInteger(Number(value))) return 'Must be an integer';
    return null;
  },
  
  positive: (value) => {
    if (!value) return null;
    if (Number(value) <= 0) return 'Must be positive';
    return null;
  },
  
  range: (min, max) => (value) => {
    if (!value) return null;
    const num = Number(value);
    if (num < min || num > max) return `Must be between ${min} and ${max}`;
    return null;
  },
  
  json: (value) => {
    if (!value) return null;
    try {
      JSON.parse(value);
      return null;
    } catch {
      return 'Invalid JSON';
    }
  },
  
  alphanumeric: (value) => {
    if (!value) return null;
    if (!/^[a-zA-Z0-9._-]+$/.test(value)) return 'Only letters, numbers, dots, underscores, and hyphens allowed';
    return null;
  },
  
  noSpaces: (value) => {
    if (!value) return null;
    if (/\s/.test(value)) return 'Spaces not allowed';
    return null;
  }
};

export function validateForm(formData, rules) {
  const errors = {};
  let isValid = true;
  
  for (const [field, fieldRules] of Object.entries(rules)) {
    const value = formData[field];
    for (const rule of fieldRules) {
      const error = rule(value);
      if (error) {
        errors[field] = error;
        isValid = false;
        break;
      }
    }
  }
  
  return { isValid, errors };
}

export function validateField(value, rules) {
  for (const rule of rules) {
    const error = rule(value);
    if (error) return error;
  }
  return null;
}

export const commonRules = {
  email: [validators.required, validators.email],
  password: [validators.required, validators.minLength(8)],
  name: [validators.required, validators.minLength(2), validators.maxLength(100)],
  url: [validators.required, validators.url],
  apiKey: [validators.required, validators.minLength(10)],
  siteName: [validators.required, validators.alphanumeric, validators.minLength(2)],
  port: [validators.required, validators.integer, validators.range(1, 65535)],
  budget: [validators.required, validators.numeric, validators.positive],
  cron: [validators.required, validators.pattern(/^(@\w+|(\*|\d+|\d+-\d+|\d+\/\d+)(\s+){4}(\*|\d+|\d+-\d+|\d+\/\d+))$/, 'Invalid cron expression')]
};

export function sanitizeInput(input) {
  if (typeof input !== 'string') return input;
  return input
    .replace(/[<>]/g, '')
    .trim();
}

export function sanitizeObject(obj) {
  const sanitized = {};
  for (const [key, value] of Object.entries(obj)) {
    if (typeof value === 'string') {
      sanitized[key] = sanitizeInput(value);
    } else if (typeof value === 'object' && value !== null) {
      sanitized[key] = sanitizeObject(value);
    } else {
      sanitized[key] = value;
    }
  }
  return sanitized;
}
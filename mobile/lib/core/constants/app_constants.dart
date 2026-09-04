class AppConstants {
  static const String supabaseUrl = 'https://ikooebbiodhqfjfqwjsa.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imlrb29lYmJpb2RocWZqZnF3anNhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODgwOTUyMTUsImV4cCI6MjEwMzY3MTIxNX0.jAbFJmpKxszbZougFUjYXKGGHj68Ys4tj7MWAj1c-2g';

  static const List<String> defaultPreferredDays = [
    'Monday',
    'Wednesday',
    'Friday'
  ];

  static const List<String> skillLevels = [
    'Beginner',
    'Intermediate',
    'Advanced',
    'Expert'
  ];

  static const List<String> skillCategories = [
    'Programming',
    'Design',
    'Language',
    'Music',
    'Fitness',
    'Business',
    'General'
  ];

  static const List<String> expenseCategories = [
    'food',
    'transport',
    'shopping',
    'education',
    'entertainment',
    'bills',
    'health',
    'travel',
    'personal',
    'subscriptions',
    'family',
    'other'
  ];

  static const List<String> paymentMethods = [
    'cash',
    'upi',
    'debit_card',
    'credit_card',
    'bank_transfer',
    'other'
  ];
}

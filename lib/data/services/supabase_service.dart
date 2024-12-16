import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // Singleton instance
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  // Supabase client
  final SupabaseClient _supabase = Supabase.instance.client;

  // Getters for easy access
  SupabaseClient get client => _supabase;
  SupabaseQueryBuilder table(String tableName) => _supabase.from(tableName);
}

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'models.dart';
import 'services/fountain_parser.dart';

class AppState extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  // --- THEME STATE ---
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  // --- AUTH STATE ---
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 1. Google Sign In (Restored)
  Future<void> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Load IDs from .env to prevent crashes if hardcoded wrong
      final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
      final iosClientId = dotenv.env['GOOGLE_IOS_CLIENT_ID'];

      if (webClientId == null || iosClientId == null) {
        throw 'Google Client IDs not found in .env file.';
      }

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: iosClientId,
        serverClientId: webClientId,
      );

      final googleUser = await googleSignIn.signIn();
      final googleAuth = await googleUser?.authentication;

      if (googleAuth == null) {
        throw 'Google Sign-In cancelled.';
      }

      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      await fetchScripts();
    } catch (e) {
      debugPrint("Google Login Error: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. Email Login
  Future<void> signInWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) throw 'Login failed.';
      await fetchScripts();
    } catch (e) {
      debugPrint("Email Login Error: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 3. Email Sign Up
  Future<void> signUpWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      if (response.user == null) throw 'Sign up failed.';
      await fetchScripts();
    } catch (e) {
      debugPrint("Sign Up Error: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _supabase.auth.signOut();
      _clearLocalData();
    } catch (e) {
      debugPrint("Sign Out Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _clearLocalData() {
    _myScripts = [];
    _currentScriptId = null;
    _currentScriptTitle = "Untitled";
    scriptController.clear();
    _scenes = [];
    _strokes = [];
    _redoStack = [];
    _isStoryboardOpen = false;
  }

  // --- EDITOR STATE & LOGIC ---
  // (Keep all existing editor logic below unchanged)
  final TextEditingController scriptController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  String? _currentScriptId;
  String _currentScriptTitle = "Untitled";
  String _syncStatus = 'Offline';
  Timer? _debounceTimer;
  List<Map<String, dynamic>> _myScripts = [];
  bool _isStoryboardOpen = false;
  List<SceneHeading> _scenes = [];
  List<DrawingStroke> _strokes = [];
  List<DrawingStroke> _redoStack = [];
  Color _currentColor = Colors.black;
  double _currentWidth = 4.0;
  bool _isEraser = false;

  List<Map<String, dynamic>> get myScripts => _myScripts;
  String get currentScriptTitle => _currentScriptTitle;
  bool get isStoryboardOpen => _isStoryboardOpen;
  List<SceneHeading> get scenes => _scenes;
  List<DrawingStroke> get strokes => _strokes;
  Color get currentColor => _currentColor;
  double get currentWidth => _currentWidth;
  bool get isEraser => _isEraser;
  String get syncStatus => _syncStatus;

  AppState() {
    _initAuthAndLoad();
    scriptController.addListener(_onTextChanged);
  }

  Future<void> _initAuthAndLoad() async {
    final session = _supabase.auth.currentSession;
    if (session != null) await fetchScripts();
  }

  Future<void> fetchScripts() async {
    if (_supabase.auth.currentUser == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final userId = _supabase.auth.currentUser!.id;
      final data = await _supabase
          .from('scripts')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false);
      _myScripts = List<Map<String, dynamic>>.from(data);
      _syncStatus = 'Synced';
    } catch (e) {
      _syncStatus = 'Offline';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createNewScript(BuildContext context) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final userName =
          _supabase.auth.currentUser!.email?.split('@')[0] ?? 'Writer';
      final titlePageTemplate =
          "Title: UNTITLED SCRIPT\nCredit: written by\nAuthor: $userName\n\nINT. START - DAY\n\n";
      final newScript = await _supabase
          .from('scripts')
          .insert({
            'user_id': userId,
            'title': 'Untitled Script',
            'content': titlePageTemplate,
          })
          .select()
          .single();
      await openScript(newScript['id'], titlePageTemplate, 'Untitled Script');
    } catch (e) {
      debugPrint("Create Error: $e");
    }
  }

  Future<void> openScript(String id, String content, String title) async {
    _currentScriptId = id;
    _currentScriptTitle = title;
    scriptController.text = content;
    _parseScenes();
    _strokes.clear();
    _syncStatus = 'Synced';
  }

  Future<void> deleteScript(String id) async {
    await _supabase.from('scripts').delete().eq('id', id);
    await fetchScripts();
  }

  Future<void> updateTitle(String newTitle) async {
    _currentScriptTitle = newTitle;
    notifyListeners();
    if (_currentScriptId != null) {
      await _supabase
          .from('scripts')
          .update({'title': newTitle})
          .eq('id', _currentScriptId!);
      fetchScripts();
    }
  }

  void insertElement(String type) {
    String textToInsert = "";
    switch (type) {
      case 'scene':
        textToInsert = "\n\nINT. ";
        break;
      case 'ext':
        textToInsert = "\n\nEXT. ";
        break;
      case 'action':
        textToInsert = "\n\n";
        break;
      case 'character':
        textToInsert = "\n\n@";
        break;
      case 'parenthetical':
        textToInsert = "\n(";
        break;
      case 'dialogue':
        textToInsert = "\n";
        break;
      case 'transition':
        textToInsert = "\n\nCUT TO:";
        break;
      case 'shot':
        textToInsert = "\n\nCLOSE ON: ";
        break;
    }
    final text = scriptController.text;
    final selection = scriptController.selection;
    int cursor = selection.isValid ? selection.end : text.length;
    if (cursor < 0) cursor = 0;
    if (cursor > text.length) cursor = text.length;
    final newText = text.replaceRange(cursor, cursor, textToInsert);
    scriptController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor + textToInsert.length),
    );
  }

  void _onTextChanged() {
    _parseScenes();
    _syncStatus = 'Unsaved changes...';
    notifyListeners();
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), _saveToCloud);
  }

  Future<void> _saveToCloud() async {
    if (_currentScriptId == null) return;
    _syncStatus = 'Syncing...';
    notifyListeners();
    try {
      await _supabase
          .from('scripts')
          .update({
            'content': scriptController.text,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _currentScriptId!);
      _syncStatus = 'All changes saved';
    } catch (e) {
      _syncStatus = 'Offline (Saved locally)';
    }
    notifyListeners();
  }

  void _parseScenes() {
    final text = scriptController.text;
    final lines = text.split('\n');
    final newScenes = <SceneHeading>[];
    int currentPos = 0;
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (RegExp(
        r'^(INT\.|EXT\.|EST\.|I\/E|INT\/EXT)[\.\s]',
        caseSensitive: false,
      ).hasMatch(line)) {
        newScenes.add(
          SceneHeading(
            text: line,
            position: currentPos,
            type: line.toUpperCase().startsWith('INT') ? 'INT' : 'EXT',
            index: newScenes.length + 1,
          ),
        );
      }
      currentPos += lines[i].length + 1;
    }
    _scenes = newScenes;
    notifyListeners();
  }

  void toggleStoryboard() {
    _isStoryboardOpen = !_isStoryboardOpen;
    notifyListeners();
  }

  void navigateToScene(int pos) {
    scriptController.selection = TextSelection.collapsed(offset: pos);
  }

  void addStroke(DrawingStroke s) {
    _strokes.add(s);
    _redoStack.clear();
    notifyListeners();
  }

  void undo() {
    if (_strokes.isNotEmpty) {
      _redoStack.add(_strokes.removeLast());
      notifyListeners();
    }
  }

  void redo() {
    if (_redoStack.isNotEmpty) {
      _strokes.add(_redoStack.removeLast());
      notifyListeners();
    }
  }

  void clearCanvas() {
    _strokes.clear();
    _redoStack.clear();
    notifyListeners();
  }

  void setTool(Color c, double w, bool e) {
    _currentColor = c;
    _currentWidth = w;
    _isEraser = e;
    notifyListeners();
  }
}

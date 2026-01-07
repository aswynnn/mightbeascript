import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../app_state.dart';
import 'editor_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = state.isDarkMode;

    // Theme Colors
    final bgColor = isDark ? const Color(0xFF111827) : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF1F2937) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[500];
    final borderColor = isDark
        ? Colors.white10
        : Colors.black.withOpacity(0.06);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        centerTitle: false,
        shape: Border(bottom: BorderSide(color: borderColor)),
        title: Row(
          children: [
            Icon(LucideIcons.feather, size: 20, color: Colors.blue[500]),
            const SizedBox(width: 12),
            Text(
              'Might Be A Script', // UPDATED
              style: GoogleFonts.inter(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? LucideIcons.sun : LucideIcons.moon, size: 20),
            color: isDark ? Colors.white70 : Colors.grey[700],
            onPressed: () => state.toggleTheme(),
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: const Icon(LucideIcons.logOut, size: 20),
            color: isDark ? Colors.red[300] : Colors.red[400],
            tooltip: 'Sign Out',
            onPressed: () => _handleSignOut(context, isDark),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Projects',
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              letterSpacing: -1,
                            ),
                          ),
                          Text(
                            '${state.myScripts.length} scripts',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: subTextColor,
                            ),
                          ),
                        ],
                      ),

                      ElevatedButton.icon(
                        onPressed: () async {
                          await state.createNewScript(context);
                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EditorScreen(),
                              ),
                            );
                          }
                        },
                        icon: const Icon(LucideIcons.plus, size: 18),
                        label: const Text('New Script'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Grid
                  Expanded(
                    child: state.myScripts.isEmpty
                        ? _buildEmptyState(isDark)
                        : GridView.builder(
                            padding: const EdgeInsets.only(bottom: 32),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 280,
                                  childAspectRatio: 0.75,
                                  crossAxisSpacing: 24,
                                  mainAxisSpacing: 24,
                                ),
                            itemCount: state.myScripts.length,
                            itemBuilder: (context, index) {
                              final script = state.myScripts[index];
                              return _ScriptCard(
                                script: script,
                                isDark: isDark,
                                onTap: () async {
                                  await state.openScript(
                                    script['id'],
                                    script['content'] ?? '',
                                    script['title'] ?? 'Untitled',
                                  );
                                  if (context.mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const EditorScreen(),
                                      ),
                                    );
                                  }
                                },
                                onDelete: () =>
                                    state.deleteScript(script['id']),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.fileText,
              size: 48,
              color: isDark ? Colors.white24 : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "No scripts yet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Create a new script to get started",
            style: TextStyle(
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 64),
        ],
      ),
    );
  }

  Future<void> _handleSignOut(BuildContext context, bool isDark) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Sign Out',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      await context.read<AppState>().signOut();
    }
  }
}

class _ScriptCard extends StatelessWidget {
  final Map<String, dynamic> script;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ScriptCard({
    required this.script,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(script['updated_at']);
    final bgColor = isDark ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = isDark
        ? Colors.white10
        : Colors.black.withOpacity(0.06);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withOpacity(0.2)
                      : const Color(0xFFF9FAFB),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                ),
                child: Text(
                  script['content'] ?? '',
                  style: GoogleFonts.courierPrime(
                    fontSize: 4,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                    height: 1.2,
                  ),
                  overflow: TextOverflow.fade,
                ),
              ),
            ),

            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          script['title'] ?? 'Untitled',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark ? Colors.white : Colors.black87,
                            fontFamily: 'Inter',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Edited ${DateFormat.MMMd().format(date)}',
                          style: TextStyle(
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: PopupMenuButton(
                        icon: Icon(
                          LucideIcons.moreHorizontal,
                          size: 16,
                          color: isDark ? Colors.grey[400] : Colors.grey[400],
                        ),
                        color: isDark ? const Color(0xFF374151) : Colors.white,
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.trash2,
                                  size: 14,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (val) {
                          if (val == 'delete') onDelete();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

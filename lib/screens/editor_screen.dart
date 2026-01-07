import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../app_state.dart';
import '../services/fountain_parser.dart';
import '../widgets/storyboard_panel.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  bool _showPreview = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = state.isDarkMode;

    // --- iOS INSPIRED THEME ---
    final bgColor = isDark ? const Color(0xFF111827) : const Color(0xFFF2F2F7);
    final paperColor = isDark ? const Color(0xFF1F2937) : Colors.white;
    final textColor = isDark ? const Color(0xFFE5E7EB) : Colors.black87;
    final sidebarColor = isDark
        ? const Color(0xFF1F2937)
        : Colors.white.withOpacity(0.9);
    final borderColor = isDark
        ? Colors.white10
        : Colors.black.withOpacity(0.06);

    return Scaffold(
      backgroundColor: bgColor,
      body: Row(
        children: [
          // Sidebar (Fixed width)
          SizedBox(width: 260, child: ContextSidebar(isDark: isDark)),

          // Divider
          Container(width: 1, color: borderColor),

          // Main Content
          Expanded(
            child: Stack(
              children: [
                Column(
                  children: [
                    // Top Bar (Blurred Glass effect)
                    ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          height: 54,
                          decoration: BoxDecoration(
                            color: sidebarColor,
                            border: Border(
                              bottom: BorderSide(color: borderColor),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  LucideIcons.chevronLeft,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                                onPressed: () {
                                  state.fetchScripts();
                                  Navigator.pop(context);
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller:
                                      TextEditingController(
                                          text: state.currentScriptTitle,
                                        )
                                        ..selection = TextSelection.collapsed(
                                          offset:
                                              state.currentScriptTitle.length,
                                        ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                  ),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: textColor,
                                    fontFamily: 'Inter',
                                  ),
                                  onSubmitted: (val) => state.updateTitle(val),
                                ),
                              ),
                              // View Toggle (Segmented Control style)
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.black26
                                      : Colors.black.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.all(3),
                                child: Row(
                                  children: [
                                    _ViewToggleBtn(
                                      label: 'Edit',
                                      active: !_showPreview,
                                      onTap: () =>
                                          setState(() => _showPreview = false),
                                      isDark: isDark,
                                    ),
                                    _ViewToggleBtn(
                                      label: 'View',
                                      active: _showPreview,
                                      onTap: () =>
                                          setState(() => _showPreview = true),
                                      isDark: isDark,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Editor Canvas
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!_showPreview)
                            FocusScope.of(context).requestFocus(FocusNode());
                        },
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(32, 32, 32, 140),
                          child: Center(
                            child: Container(
                              width: 794,
                              constraints: const BoxConstraints(
                                minHeight: 1123,
                              ),
                              decoration: BoxDecoration(
                                color: paperColor,
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(
                                      isDark ? 0.4 : 0.08,
                                    ),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(72),
                              child: _showPreview
                                  ? FountainRenderer(
                                      content: state.scriptController.text,
                                      textColor: textColor,
                                    )
                                  : TextField(
                                      controller: state.scriptController,
                                      maxLines: null,
                                      style: GoogleFonts.courierPrime(
                                        fontSize: 16,
                                        color: textColor,
                                        height: 1.2,
                                      ),
                                      cursorColor: Colors.blue,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true,
                                        hintText: 'Start writing...',
                                        hintStyle: TextStyle(
                                          color: isDark
                                              ? Colors.white24
                                              : Colors.black12,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Floating Toolbar
                const Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(child: FormatToolbar()),
                ),

                // Storyboard Panel
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  top: 0,
                  bottom: 0,
                  right: state.isStoryboardOpen ? 0 : -500,
                  width: 500,
                  child: const StoryboardPanel(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- RENDERER ---
class FountainRenderer extends StatelessWidget {
  final String content;
  final Color textColor;
  const FountainRenderer({
    super.key,
    required this.content,
    this.textColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    final blocks = FountainEngine.parse(content);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks.map((block) {
        if (block.type == FountainType.titlePage) {
          final meta = block.metadata ?? {};
          return SizedBox(
            height: 900,
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  meta['title']?.toUpperCase() ?? 'UNTITLED',
                  style: GoogleFonts.courierPrime(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  meta['credit'] ?? 'written by',
                  style: GoogleFonts.courierPrime(
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  meta['author'] ?? 'Author',
                  style: GoogleFonts.courierPrime(
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          );
        }
        TextAlign align = TextAlign.left;
        if (block.type == FountainType.transition) align = TextAlign.right;
        if (block.type == FountainType.centered) align = TextAlign.center;
        return Padding(
          padding: FountainEngine.getPadding(block.type),
          child: SizedBox(
            width: double.infinity,
            child: Text(
              block.text,
              textAlign: align,
              style: FountainEngine.getStyle(block.type).copyWith(
                fontFamily: GoogleFonts.courierPrime().fontFamily,
                fontSize: 16,
                color: textColor,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// --- TOOLBAR (Fixed Icons) ---
class FormatToolbar extends StatelessWidget {
  const FormatToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final isDark = context.watch<AppState>().isDarkMode;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withOpacity(0.6)
                : Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _FormatBtn(
                label: 'Scene',
                icon: LucideIcons.clapperboard,
                onTap: () => state.insertElement('scene'),
              ),
              _FormatBtn(
                label: 'Action',
                icon: LucideIcons.alignLeft,
                onTap: () => state.insertElement('action'),
              ),
              _FormatBtn(
                label: 'Char',
                icon: LucideIcons.user,
                onTap: () => state.insertElement('character'),
              ),
              _FormatBtn(
                label: 'Dial',
                icon: LucideIcons.messageSquare,
                onTap: () => state.insertElement('dialogue'),
              ),
              // FIX: Replaced LucideIcons.parentheses with LucideIcons.italic since parentheses isn't standard in the Flutter package
              _FormatBtn(
                label: 'Paren',
                icon: LucideIcons.italic,
                onTap: () => state.insertElement('parenthetical'),
              ),

              Container(
                width: 1,
                height: 24,
                color: isDark ? Colors.white24 : Colors.black12,
                margin: const EdgeInsets.symmetric(horizontal: 6),
              ),

              _FormatBtn(
                label: 'Trans',
                icon: LucideIcons.arrowRightToLine,
                onTap: () => state.insertElement('transition'),
              ),
              _FormatBtn(
                label: 'Shot',
                icon: LucideIcons.camera,
                onTap: () => state.insertElement('shot'),
              ),

              Container(
                width: 1,
                height: 24,
                color: isDark ? Colors.white24 : Colors.black12,
                margin: const EdgeInsets.symmetric(horizontal: 6),
              ),

              IconButton(
                icon: const Icon(LucideIcons.palette, size: 20),
                onPressed: state.toggleStoryboard,
                tooltip: 'Storyboard',
                color: isDark ? Colors.white : Colors.black87,
              ),
              const ExportButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormatBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _FormatBtn({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppState>().isDarkMode;
    final color = isDark ? Colors.white : Colors.black87;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 50,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- CONTEXT SIDEBAR (Fixed Icons) ---
class ContextSidebar extends StatelessWidget {
  final bool isDark;
  const ContextSidebar({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final bgColor = isDark ? const Color(0xFF1F2937) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final borderColor = isDark
        ? Colors.white10
        : Colors.black.withOpacity(0.06);

    return Container(
      color: bgColor,
      child: Column(
        children: [
          const SizedBox(height: 54),

          // 1. QUICK INSERT HEADER
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => state.insertElement('scene'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      foregroundColor: Colors.blue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      "INT.",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => state.insertElement('ext'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.withOpacity(0.1),
                      foregroundColor: Colors.green,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      "EXT.",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. SCENES LIST
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(
                  LucideIcons.list,
                  size: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'OUTLINE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: state.scenes.length,
              itemBuilder: (context, index) {
                final scene = state.scenes[index];
                return InkWell(
                  onTap: () => state.navigateToScene(scene.position),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: scene.type == 'INT'
                                ? Colors.blue
                                : Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            scene.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: textColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          "#${index + 1}",
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. SYNC STATUS INDICATOR (Fixed Icon)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                // FIX: Replaced LucideIcons.cloudCheck with LucideIcons.cloud
                Icon(
                  state.syncStatus.contains('Offline') ||
                          state.syncStatus.contains('Unsaved')
                      ? LucideIcons.cloudOff
                      : LucideIcons.cloud,
                  size: 14,
                  color:
                      state.syncStatus.contains('Saved') ||
                          state.syncStatus.contains('Synced')
                      ? Colors.green
                      : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  state.syncStatus,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewToggleBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool isDark;
  const _ViewToggleBtn({
    required this.label,
    required this.active,
    required this.onTap,
    required this.isDark,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? (isDark ? const Color(0xFF6366F1) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: active && !isDark
              ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2)]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            color: active && isDark
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black),
          ),
        ),
      ),
    );
  }
}

class ExportButton extends StatelessWidget {
  const ExportButton({super.key});
  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppState>().isDarkMode;
    return PopupMenuButton<String>(
      icon: Icon(
        LucideIcons.download,
        size: 20,
        color: isDark ? Colors.white : Colors.black87,
      ),
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'pdf', child: Text('Export PDF')),
      ],
      onSelected: (_) async {
        final pdf = pw.Document();
        final font = await PdfGoogleFonts.courierPrimeRegular();
        final text = context.read<AppState>().scriptController.text;
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(72),
            build: (c) =>
                pw.Text(text, style: pw.TextStyle(font: font, fontSize: 12)),
          ),
        );
        await Printing.sharePdf(
          bytes: await pdf.save(),
          filename: 'script.pdf',
        );
      },
    );
  }
}

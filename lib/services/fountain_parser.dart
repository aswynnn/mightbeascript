import 'package:flutter/material.dart';

enum FountainType {
  titlePage,
  scene,
  action,
  character,
  dialogue,
  parenthetical,
  transition,
  shot, // Updated logic
  montageHeader, // New
  actionList, // New (Bullet points in montage)
  centered,
}

class FountainBlock {
  final String text;
  final FountainType type;
  final Map<String, String>? metadata;

  FountainBlock({required this.text, required this.type, this.metadata});
}

class FountainEngine {
  static const double pageWidth = 8.27 * 96;
  static const double pageHeight = 11.69 * 96;

  static const double _characterMargin = 3.7;
  static const double _dialogueMargin = 2.5;
  static const double _parentheticalMargin = 3.1;
  static const double _transitionMargin = 6.0;

  static List<FountainBlock> parse(String script) {
    final List<FountainBlock> blocks = [];
    final lines = script.split('\n');

    int i = 0;

    // --- 1. TITLE PAGE (Keep V6 Logic) ---
    if (lines.isNotEmpty &&
        lines[0].trim().toLowerCase().startsWith('title:')) {
      Map<String, String> titleMeta = {};
      while (i < lines.length && lines[i].trim().contains(':')) {
        final parts = lines[i].split(':');
        if (parts.length >= 2) {
          titleMeta[parts[0].trim().toLowerCase()] = parts
              .sublist(1)
              .join(':')
              .trim();
        }
        i++;
      }
      blocks.add(
        FountainBlock(
          text: '',
          type: FountainType.titlePage,
          metadata: titleMeta,
        ),
      );
      while (i < lines.length && lines[i].trim().isEmpty) i++;
    }

    // --- 2. SCRIPT PARSING ---
    for (; i < lines.length; i++) {
      String line = lines[i].trim();

      if (line.isEmpty) {
        blocks.add(FountainBlock(text: '', type: FountainType.action));
        continue;
      }

      // Explicit Centering (> <)
      if (line.startsWith('>') && line.endsWith('<') && line.length > 2) {
        blocks.add(
          FountainBlock(
            text: line.substring(1, line.length - 1).trim(),
            type: FountainType.centered,
          ),
        );
        continue;
      }

      // Forced Transition (>)
      if (line.startsWith('>') && !line.endsWith('<')) {
        blocks.add(
          FountainBlock(
            text: line.substring(1).trim().toUpperCase(),
            type: FountainType.transition,
          ),
        );
        continue;
      }

      // Scene Heading (Including Sequences like "MONTAGE - TRAINING")
      if (RegExp(
        r'^(INT\.|EXT\.|EST\.|I\/E|INT\/EXT)',
        caseSensitive: false,
      ).hasMatch(line)) {
        blocks.add(
          FountainBlock(text: line.toUpperCase(), type: FountainType.scene),
        );
        continue;
      }

      // Transition (Ends in TO:)
      if (line.toUpperCase().endsWith('TO:') && line == line.toUpperCase()) {
        blocks.add(
          FountainBlock(
            text: line.toUpperCase(),
            type: FountainType.transition,
          ),
        );
        continue;
      }

      // Character
      bool prevIsEmpty = i == 0 || lines[i - 1].trim().isEmpty;
      if (prevIsEmpty &&
          line == line.toUpperCase() &&
          !line.contains(RegExp(r'[a-z]'))) {
        blocks.add(FountainBlock(text: line, type: FountainType.character));
        continue;
      }

      // Parenthetical
      if (line.startsWith('(') && line.endsWith(')')) {
        blocks.add(FountainBlock(text: line, type: FountainType.parenthetical));
        continue;
      }

      // Dialogue
      if (blocks.isNotEmpty) {
        var lastType = blocks.last.type;
        if (lastType == FountainType.character ||
            lastType == FountainType.parenthetical) {
          blocks.add(FountainBlock(text: line, type: FountainType.dialogue));
          continue;
        }
      }

      // --- NEW V7 LOGIC ---

      // Montage Header / End
      if (line.toUpperCase().startsWith('MONTAGE') ||
          line.toUpperCase().startsWith('SERIES OF SHOTS') ||
          line.toUpperCase().startsWith('END MONTAGE')) {
        blocks.add(
          FountainBlock(
            text: line.toUpperCase(),
            type: FountainType.montageHeader,
          ),
        );
        continue;
      }

      // Bullet / Action List (Lines starting with hyphen)
      if (line.startsWith('-')) {
        blocks.add(FountainBlock(text: line, type: FountainType.actionList));
        continue;
      }

      // Shots (Camera Directions)
      // Expanded regex for common shots
      if (RegExp(
            r'^(CLOSE ON|ANGLE ON|TRACKING|ZOOM|PAN|POV|WIDE SHOT|FULL SHOT|INSERT|ESTABLISHING)',
            caseSensitive: false,
          ).hasMatch(line) &&
          line == line.toUpperCase()) {
        blocks.add(FountainBlock(text: line, type: FountainType.shot));
        continue;
      }

      // Action (Default)
      blocks.add(FountainBlock(text: line, type: FountainType.action));
    }
    return blocks;
  }

  static TextStyle getStyle(FountainType type) {
    const base = TextStyle(
      fontFamily: 'Courier Prime',
      fontSize: 12,
      color: Colors.black,
      height: 1.0,
    );

    switch (type) {
      case FountainType.scene:
        return base.copyWith(fontWeight: FontWeight.bold);
      case FountainType.shot:
        return base.copyWith(fontWeight: FontWeight.bold); // Shots are bold
      case FountainType.montageHeader:
        return base.copyWith(
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
        ); // Distinct style
      default:
        return base;
    }
  }

  static EdgeInsets getPadding(FountainType type) {
    const double inch = 72.0;

    switch (type) {
      case FountainType.character:
        return const EdgeInsets.only(
          left: _characterMargin * inch,
          top: 12,
          bottom: 0,
        );
      case FountainType.dialogue:
        return const EdgeInsets.only(
          left: _dialogueMargin * inch,
          right: 2.0 * inch,
          bottom: 0,
        );
      case FountainType.parenthetical:
        return const EdgeInsets.only(
          left: _parentheticalMargin * inch,
          bottom: 0,
        );
      case FountainType.transition:
        return const EdgeInsets.only(
          left: _transitionMargin * inch,
          top: 12,
          bottom: 12,
        );
      case FountainType.centered:
        return const EdgeInsets.only(left: 0, right: 0, top: 12, bottom: 12);
      case FountainType.scene:
        return const EdgeInsets.only(top: 18, bottom: 6);
      case FountainType.shot:
        return const EdgeInsets.only(
          top: 18,
          bottom: 6,
        ); // Similar to Scene Heading but usually single spacing
      case FountainType.montageHeader:
        return const EdgeInsets.only(top: 18, bottom: 12);
      case FountainType.actionList:
        return const EdgeInsets.only(
          left: 0.5 * inch,
          bottom: 6,
        ); // Indented bullets
      case FountainType.titlePage:
        return EdgeInsets.zero;
      case FountainType.action:
        return const EdgeInsets.only(bottom: 12);
    }
  }
}

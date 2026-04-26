import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:markdown/markdown.dart' as md;
import 'package:screenshot/screenshot.dart';
import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;

import '../features/reader/widgets/markdown_renderer.dart';

class ExportService {
  ExportService._();

  static Uint8List? _cachedCjkFont;

  static Future<pw.Font?> _loadCjkFont() async {
    if (_cachedCjkFont != null) {
      return pw.Font.ttf(ByteData.view(_cachedCjkFont!.buffer, _cachedCjkFont!.offsetInBytes, _cachedCjkFont!.length));
    }
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheFile = File('${tempDir.path}${Platform.pathSeparator}cjk_font.ttf');

      if (await cacheFile.exists()) {
        _cachedCjkFont = await cacheFile.readAsBytes();
        return pw.Font.ttf(ByteData.view(_cachedCjkFont!.buffer, _cachedCjkFont!.offsetInBytes, _cachedCjkFont!.length));
      }

      final cssUrl = Uri.parse(
        'https://fonts.googleapis.com/css2?family=Noto+Sans+SC:wght@400;700',
      );
      final cssRes = await http.get(cssUrl);
      if (cssRes.statusCode != 200) return null;

      final urlMatch =
          RegExp(r'url\((https://[^)]+)\)').firstMatch(cssRes.body);
      if (urlMatch == null) return null;

      final ttfRes = await http.get(Uri.parse(urlMatch.group(1)!));
      if (ttfRes.statusCode != 200) return null;

      unawaited(cacheFile.writeAsBytes(ttfRes.bodyBytes));
      _cachedCjkFont = ttfRes.bodyBytes;
      return pw.Font.ttf(ByteData.view(_cachedCjkFont!.buffer, _cachedCjkFont!.offsetInBytes, _cachedCjkFont!.length));
    } catch (_) {
      return null;
    }
  }

  static Future<String> exportAsPng(String content, BuildContext context) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final controller = ScreenshotController();

    final widget = InheritedTheme.captureAll(
      context,
      MediaQuery(
        data: MediaQuery.of(context),
        child: Material(
          child: Container(
            color: colorScheme.surface,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MarkdownRenderer(data: content, fontSize: theme.textTheme.bodyLarge?.fontSize),
              ],
            ),
          ),
        ),
      ),
    );

    final bytes = await controller.captureFromLongWidget(
      widget,
      pixelRatio: 3.0,
      context: context,
    );

    return _writeToTempFile(bytes, 'puremd_export.png');
  }

  static Future<String> exportAsPdf(String content) async {
    final document = md.Document(extensionSet: md.ExtensionSet.gitHubFlavored);
    final lines = content.split('\n');
    final nodes = document.parseLines(lines);

    final cjkFont = await _loadCjkFont();
    final textStyle = cjkFont != null
        ? pw.TextStyle(font: cjkFont, fontSize: 12)
        : null;

    final pdf = pw.Document();
    final widgets = <pw.Widget>[];

    for (final node in nodes) {
      _buildPdfWidgets(node, widgets, textStyle: textStyle);
    }

    if (widgets.isEmpty) {
      widgets.add(pw.Paragraph(text: ''));
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => widgets,
      ),
    );

    final bytes = await pdf.save();
    return _writeToTempFile(Uint8List.fromList(bytes), 'puremd_export.pdf');
  }

  static void _buildPdfWidgets(md.Node node, List<pw.Widget> widgets, {pw.TextStyle? textStyle}) {
    if (node is md.Element) {
      switch (node.tag) {
        case 'h1':
          widgets.add(pw.Header(
            level: 1,
            text: _extractText(node),
            textStyle: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold).merge(textStyle),
          ));
        case 'h2':
          widgets.add(pw.Header(
            level: 2,
            text: _extractText(node),
            textStyle: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold).merge(textStyle),
          ));
        case 'h3':
          widgets.add(pw.Header(
            level: 3,
            text: _extractText(node),
            textStyle: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold).merge(textStyle),
          ));
        case 'p':
          widgets.add(pw.Paragraph(text: _extractText(node), style: textStyle));
        case 'pre':
          final codeText = _extractText(node);
          widgets.add(pw.Container(
            padding: const pw.EdgeInsets.all(12),
            margin: const pw.EdgeInsets.symmetric(vertical: 6),
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            child: pw.Text(
              codeText,
              style: pw.TextStyle(font: pw.Font.courier(), fontSize: 10, lineSpacing: 2),
            ),
          ));
        case 'blockquote':
          widgets.add(pw.Container(
            padding: const pw.EdgeInsets.only(left: 12, top: 4, bottom: 4),
            margin: const pw.EdgeInsets.symmetric(vertical: 4),
            decoration: const pw.BoxDecoration(
              border: pw.Border(left: pw.BorderSide(width: 3, color: PdfColors.grey)),
            ),
            child: pw.Text(
              _extractText(node),
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700).merge(textStyle),
            ),
          ));
        case 'ul':
          for (final child in node.children ?? <md.Node>[]) {
            if (child is md.Element && child.tag == 'li') {
              widgets.add(pw.Bullet(text: _extractText(child), style: textStyle));
            }
          }
        case 'ol':
          final children = node.children ?? <md.Node>[];
          for (var i = 0; i < children.length; i++) {
            final child = children[i];
            if (child is md.Element && child.tag == 'li') {
              widgets.add(pw.Paragraph(text: '  ${i + 1}. ${_extractText(child)}', style: textStyle));
            }
          }
        case 'hr':
          widgets.add(pw.Divider());
        default:
          final text = _extractText(node);
          if (text.isNotEmpty) {
            widgets.add(pw.Paragraph(text: text, style: textStyle));
          }
      }
    } else if (node is md.Text) {
      if (node.text.trim().isNotEmpty) {
        widgets.add(pw.Paragraph(text: node.text, style: textStyle));
      }
    }
  }


  static String _extractText(md.Node node) {
    if (node is md.Text) return node.text;
    if (node is md.Element) {
      return (node.children ?? <md.Node>[])
          .map(_extractText)
          .join();
    }
    return '';
  }

  static Future<String> exportAsDocx(String content) async {
    final archive = Archive();

    // [Content_Types].xml — register all parts
    archive.addFile(ArchiveFile.string('[Content_Types].xml',
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
        '<Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>'
        '<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>'
        '<Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>'
        '</Types>'));

    // _rels/.rels
    archive.addFile(ArchiveFile.string('_rels/.rels',
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
        '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>'
        '<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>'
        '</Relationships>'));

    // word/_rels/document.xml.rels
    archive.addFile(ArchiveFile.string('word/_rels/document.xml.rels',
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
        '</Relationships>'));

    // word/styles.xml — basic styles for rendering
    archive.addFile(ArchiveFile.string('word/styles.xml',
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
        '<w:docDefaults>'
        '<w:rPrDefault><w:rPr><w:sz w:val="22"/><w:szCs w:val="22"/></w:rPr></w:rPrDefault>'
        '<w:pPrDefault><w:pPr><w:spacing w:after="120" w:line="276"/></w:pPr></w:pPrDefault>'
        '</w:docDefaults>'
        '<w:style w:type="paragraph" w:default="1" w:styleId="Normal">'
        '<w:name w:val="Normal"/>'
        '<w:qFormat/>'
        '</w:style>'
        '<w:style w:type="paragraph" w:styleId="ListParagraph">'
        '<w:name w:val="List Paragraph"/>'
        '<w:basedOn w:val="Normal"/>'
        '<w:pPr><w:ind w:left="720"/></w:pPr>'
        '</w:style>'
        '</w:styles>'));

    // docProps/core.xml
    final now = DateTime.now().toUtc().toIso8601String();
    archive.addFile(ArchiveFile.string('docProps/core.xml',
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"'
        ' xmlns:dc="http://purl.org/dc/elements/1.1/"'
        ' xmlns:dcterms="http://purl.org/dc/terms/"'
        ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
        '<dc:creator>PureMD</dc:creator>'
        '<dcterms:created xsi:type="dcterms:W3CDTF">$now</dcterms:created>'
        '</cp:coreProperties>'));

    // docProps/app.xml
    archive.addFile(ArchiveFile.string('docProps/app.xml',
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties">'
        '<Application>PureMD</Application>'
        '<DocSecurity>0</DocSecurity>'
        '<Lines>${content.split('\n').length}</Lines>'
        '</Properties>'));

    // Convert markdown to DOCX XML paragraphs & section properties
    final bodyContent = _markdownToDocxBody(content);

    // word/document.xml
    archive.addFile(ArchiveFile.string('word/document.xml',
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"'
        ' xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
        '<w:body>'
        '$bodyContent'
        '<w:sectPr>'
        '<w:pgSz w:w="11906" w:h="16838"/>'
        '<w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" w:header="720" w:footer="720" w:gutter="0"/>'
        '</w:sectPr>'
        '</w:body>'
        '</w:document>'));

    final zipData = ZipEncoder().encode(archive);
    return _writeToTempFile(Uint8List.fromList(zipData), 'puremd_export.docx');
  }

  /// Build the full body XML from markdown content.
  static String _markdownToDocxBody(String content) {
    final buffer = StringBuffer();
    final lines = content.split('\n');
    int i = 0;

    while (i < lines.length) {
      final line = lines[i];

      if (line.startsWith('### ')) {
        buffer.write(_docxPara(line.substring(4), size: 28, bold: true));
        i++;
      } else if (line.startsWith('## ')) {
        buffer.write(_docxPara(line.substring(3), size: 32, bold: true));
        i++;
      } else if (line.startsWith('# ')) {
        buffer.write(_docxPara(line.substring(2), size: 36, bold: true));
        i++;
      } else if (line.trimLeft().startsWith('```')) {
        final codeLines = <String>[];
        i++;
        while (i < lines.length && !lines[i].trimLeft().startsWith('```')) {
          codeLines.add(lines[i]);
          i++;
        }
        i++;
        buffer.write(_docxPara(codeLines.join('\n'), font: 'Courier New', size: 20));
      } else if (line.startsWith('> ')) {
        final quoteLines = <String>[line.substring(2)];
        i++;
        while (i < lines.length && lines[i].startsWith('> ')) {
          quoteLines.add(lines[i].substring(2));
          i++;
        }
        buffer.write(_docxPara(quoteLines.join('\n'), italic: true));
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        buffer.write(_docxPara(line.substring(2), bullet: true));
        i++;
      } else if (RegExp(r'^\d+\.\s').hasMatch(line)) {
        final text = line.replaceFirst(RegExp(r'^\d+\.\s*'), '');
        buffer.write(_docxPara(text, bullet: false));
        i++;
      } else if (line.trim() == '---' || line.trim() == '***' || line.trim() == '___') {
        buffer.write('<w:p><w:pPr><w:pBdr><w:bottom w:val="single" w:sz="6" w:space="1" w:color="auto"/></w:pBdr></w:pPr></w:p>');
        i++;
      } else if (line.trim().isNotEmpty) {
        buffer.write(_docxPara(line));
        i++;
      } else {
        buffer.write('<w:p></w:p>');
        i++;
      }
    }

    return buffer.toString();
  }

  /// Build a single paragraph with inline formatting support.
  static String _docxPara(String text, {double? size, bool bold = false, bool italic = false, String? font, bool bullet = false}) {
    final runs = _buildInlineRuns(text, size: size, bold: bold, italic: italic, font: font);
    final bulletPrefix = bullet ? '<w:pPr><w:pStyle w:val="ListParagraph"/></w:pPr>' : '';
    return '<w:p>$bulletPrefix$runs</w:p>';
  }

  /// Split text by inline markdown markers (**, *, `) and build runs.
  static String _buildInlineRuns(String text, {double? size, bool bold = false, bool italic = false, String? font}) {
    final segments = <_InlineSegment>[];
    _parseInline(text, segments);

    final buffer = StringBuffer();
    for (final seg in segments) {
      final b = bold || seg.bold;
      final i = italic || seg.italic;
      final f = seg.code ? 'Courier New' : font;
      buffer.write(_runXml(seg.text, bold: b, italic: i, font: f, size: size));
    }
    return buffer.toString();
  }

  /// Parse a string into inline segments with formatting.
  static void _parseInline(String text, List<_InlineSegment> out) {
    final regex = RegExp(r'(\*\*\*(.+?)\*\*\*|\*\*(.+?)\*\*|\*(.+?)\*|`(.+?)`)');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      // Plain text before this match
      if (match.start > lastEnd) {
        out.add(_InlineSegment(text.substring(lastEnd, match.start), bold: false, italic: false, code: false));
      }
      final full = match.group(0)!;
      if (full.startsWith('***')) {
        out.add(_InlineSegment(match.group(2)!, bold: true, italic: true, code: false));
      } else if (full.startsWith('**')) {
        out.add(_InlineSegment(match.group(3)!, bold: true, italic: false, code: false));
      } else if (full.startsWith('*')) {
        out.add(_InlineSegment(match.group(4)!, bold: false, italic: true, code: false));
      } else if (full.startsWith('`')) {
        out.add(_InlineSegment(match.group(5)!, bold: false, italic: false, code: true));
      }
      lastEnd = match.end;
    }

    // Remaining plain text
    if (lastEnd < text.length) {
      out.add(_InlineSegment(text.substring(lastEnd), bold: false, italic: false, code: false));
    }
  }

  /// Build a single `w:r` XML element.
  static String _runXml(String text, {bool bold = false, bool italic = false, String? font, double? size}) {
    if (text.isEmpty) return '';
    final escaped = _escapeXml(text);
    final props = StringBuffer();
    if (bold) props.write('<w:b/>');
    if (italic) props.write('<w:i/>');
    if (font != null) {
      props.write('<w:rFonts w:ascii="$font" w:hAnsi="$font" w:cs="$font"/>');
    }
    final sz = size != null ? (size * 2).toInt() : 22;
    props.write('<w:sz w:val="$sz"/><w:szCs w:val="$sz"/>');
    return '<w:r><w:rPr>$props</w:rPr><w:t xml:space="preserve">$escaped</w:t></w:r>';
  }

  static String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static Future<String> _writeToTempFile(Uint8List bytes, String fileName) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }
}

class _InlineSegment {
  final String text;
  final bool bold;
  final bool italic;
  final bool code;
  _InlineSegment(this.text, {required this.bold, required this.italic, required this.code});
}

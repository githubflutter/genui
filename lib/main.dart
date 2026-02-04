import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'json_runtime_renderer.dart';
import 'json_to_flutter_emitter.dart';

const String masterDetailJson = r'''
{
  "type": "Scaffold",
  "props": {
    "appBar": {"type": "AppBar", "props": {"title": "Customers"}},
    "drawer": {
      "type": "Drawer",
      "children": [
        {"type": "ListTile", "props": {"title": "Home", "leading": "home", "onTap": "noop", "objectId": "home"}},
        {"type": "ListTile", "props": {"title": "Settings", "leading": "settings", "onTap": "noop", "objectId": "settings"}}
      ]
    }
  },
  "child": {
    "type": "ListView",
    "children": [
      {
        "type": "Card",
        "child": {
          "type": "ListTile",
          "props": {
            "title": "Alice",
            "subtitle": "Premium",
            "trailing": "edit",
            "onTap": "noop",
            "objectId": "customer_alice"
          }
        }
      },
      {
        "type": "Card",
        "child": {
          "type": "ListTile",
          "props": {
            "title": "Bob",
            "subtitle": "Standard",
            "trailing": "edit",
            "onTap": "noop",
            "objectId": "customer_bob"
          }
        }
      }
    ]
  }
}
''';

const String editFormJson = r'''
{
  "type": "Scaffold",
  "props": {
    "appBar": {"type": "AppBar", "props": {"title": "Edit Customer"}}
  },
  "child": {
    "type": "Padding",
    "props": {"padding": "EdgeInsets.all(16)"},
    "child": {
      "type": "Form",
      "children": [
        {"type": "TextFormField", "props": {"labelText": "Name", "objectId": "name"}},
        {"type": "TextFormField", "props": {"labelText": "Email", "objectId": "email"}},
        {"type": "Switch", "props": {"value": true, "objectId": "active"}},
        {"type": "Button", "props": {"text": "Save", "onPressed": "noop", "objectId": "save"}}
      ]
    }
  }
}
''';

void main() {
  runApp(const UiJsonGenApp());
}

class UiJsonGenApp extends StatelessWidget {
  const UiJsonGenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UiJsonGen',
      theme: ThemeData(useMaterial3: true),
      home: const StartupScreen(),
    );
  }
}

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GenUI')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Start', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : () => _openStudio(),
                child: const Text('GenUiStudio'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _loading ? null : _chooseJson,
                child: const Text('Choose Json'),
              ),
              if (_loading) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openStudio({String? initialTarget}) async {
    setState(() => _loading = true);
    final uiJson = await rootBundle.loadString('assets/jsons/genuistudio.json');
    final componentsJson = await rootBundle.loadString('assets/jsons/components.json');
    if (!mounted) return;
    setState(() => _loading = false);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UiJsonGenScreen(
          uiJson: uiJson,
          initialTarget: initialTarget ?? masterDetailJson,
          componentsJson: componentsJson,
        ),
      ),
    );
  }

  Future<void> _chooseJson() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Paste JSON'),
          content: SizedBox(
            width: 420,
            child: TextField(
              controller: controller,
              minLines: 6,
              maxLines: 12,
              decoration: const InputDecoration(
                hintText: '{\n  "type": "Container"\n}',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Load'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      await _openStudio(initialTarget: result);
    }
  }
}

class UiJsonGenScreen extends StatefulWidget {
  const UiJsonGenScreen({super.key, required this.uiJson, required this.initialTarget, required this.componentsJson});

  final String uiJson;
  final String initialTarget;
  final String componentsJson;

  @override
  State<UiJsonGenScreen> createState() => _UiJsonGenScreenState();
}

class _UiJsonGenScreenState extends State<UiJsonGenScreen> {
  late final TextEditingController _targetController;
  late final TextEditingController _propTypeController;
  late final TextEditingController _propObjectIdController;
  late final TextEditingController _propTextController;
  late final TextEditingController _propColorController;
  late final TextEditingController _propPaddingController;
  late final JsonWidgetFactory _uiFactory;
  late final JsonWidgetFactory _previewFactory;
  final JsonToFlutterEmitter _emitter = JsonToFlutterEmitter();
  String _errorText = '';
  String _previewMode = 'preview';
  String _selectedPath = '';

  @override
  void initState() {
    super.initState();
    _targetController = TextEditingController(text: widget.initialTarget);
    _propTypeController = TextEditingController();
    _propObjectIdController = TextEditingController();
    _propTextController = TextEditingController();
    _propColorController = TextEditingController();
    _propPaddingController = TextEditingController();

    _previewFactory = JsonWidgetFactory(
      actionRegistry: {
        'noop': () {},
      },
    );

    _uiFactory = JsonWidgetFactory(
      actionRegistry: {
        'noop': () {},
        'formatJson': _formatJson,
        'clearJson': _clearJson,
        'applyProps': _applyProps,
      },
      stringChangedRegistry: {
        'updateTarget': (value) => _validateJson(value),
        'addComponent': (value) => _appendComponentJson(value),
      },
      controllerRegistry: {
        'target': _targetController,
        'propType': _propTypeController,
        'propObjectId': _propObjectIdController,
        'propText': _propTextController,
        'propColor': _propColorController,
        'propPadding': _propPaddingController,
      },
      jsonResolver: (key) {
        if (key == 'target') return _targetController.text;
        if (key == 'components') return widget.componentsJson;
        return '';
      },
      textResolver: (key) {
        if (key == 'errorText') return _errorText;
        if (key == 'previewMode') return _previewMode;
        if (key == 'selectedPath') return _selectedPath.isEmpty ? 'No selection' : _selectedPath;
        return '';
      },
      selectedResolver: (key) => key == 'selectedNode' ? _selectedPath : '',
      nodeSelectedRegistry: {
        'selectedNode': (path) => _onSelectNode(path),
      },
      previewBuilder: (json) => _buildPreview(json),
      dartPreviewBuilder: (json) => _buildDartPreview(json),
    );

    _validateJson(_targetController.text);
  }

  @override
  void dispose() {
    _targetController.dispose();
    _propTypeController.dispose();
    _propObjectIdController.dispose();
    _propTextController.dispose();
    _propColorController.dispose();
    _propPaddingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _uiFactory.buildFromJson(widget.uiJson);
  }

  Widget _buildPreview(String json) {
    try {
      return _previewFactory.buildFromJson(json);
    } catch (e) {
      return Center(
        child: Text('Invalid JSON: $e', textAlign: TextAlign.center),
      );
    }
  }

  Widget _buildDartPreview(String json) {
    try {
      final dart = _emitter.emitFromJson(json);
      return SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: SelectableText(
          dart,
          style: const TextStyle(fontFamily: 'monospace'),
        ),
      );
    } catch (e) {
      return Center(child: Text('Export error: $e', textAlign: TextAlign.center));
    }
  }

  void _onSelectNode(String path) {
    setState(() => _selectedPath = path);
    _loadSelectedProperties();
  }

  void _loadSelectedProperties() {
    final node = _getNodeAtPath(_selectedPath);
    if (node == null) {
      _propTypeController.text = '';
      _propObjectIdController.text = '';
      _propTextController.text = '';
      _propColorController.text = '';
      _propPaddingController.text = '';
      return;
    }

    _propTypeController.text = node['type']?.toString() ?? '';
    _propObjectIdController.text = node['objectId']?.toString() ?? node['id']?.toString() ?? '';
    final props = node['props'] is Map<String, dynamic> ? node['props'] as Map<String, dynamic> : const {};
    _propTextController.text = props['text']?.toString() ?? '';
    _propColorController.text = props['color']?.toString() ?? '';
    _propPaddingController.text = props['padding']?.toString() ?? '';
  }

  void _applyProps() {
    if (_selectedPath.isEmpty) return;
    final root = _decodeTarget();
    if (root == null) return;

    final node = _getNodeAtPath(_selectedPath, root: root);
    if (node == null) return;

    if (_propTypeController.text.trim().isNotEmpty) {
      node['type'] = _propTypeController.text.trim();
    }

    if (_propObjectIdController.text.trim().isNotEmpty) {
      node['objectId'] = _propObjectIdController.text.trim();
    }

    final props = (node['props'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    if (_propTextController.text.trim().isNotEmpty) {
      props['text'] = _propTextController.text.trim();
    }
    if (_propColorController.text.trim().isNotEmpty) {
      props['color'] = _propColorController.text.trim();
    }
    if (_propPaddingController.text.trim().isNotEmpty) {
      props['padding'] = _propPaddingController.text.trim();
    }
    if (props.isNotEmpty) node['props'] = props;

    _targetController.text = const JsonEncoder.withIndent('  ').convert(root);
    _validateJson(_targetController.text);
  }

  Map<String, dynamic>? _decodeTarget() {
    try {
      final decoded = jsonDecode(_targetController.text);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }

  Map<String, dynamic>? _getNodeAtPath(String path, {Map<String, dynamic>? root}) {
    if (path.isEmpty) return null;
    root ??= _decodeTarget();
    if (root == null) return null;

    var current = root as Map<String, dynamic>;
    if (path == 'root') return current;

    var remaining = path;
    if (remaining.startsWith('root.')) remaining = remaining.substring(5);
    final parts = remaining.split('.');

    for (final part in parts) {
      if (part == 'child') {
        if (current['child'] is Map<String, dynamic>) {
          current = current['child'] as Map<String, dynamic>;
        } else {
          return null;
        }
      } else if (part.startsWith('children[')) {
        final indexStr = part.substring(9, part.length - 1);
        final index = int.tryParse(indexStr) ?? -1;
        final children = current['children'] as List?;
        if (children == null || index < 0 || index >= children.length) return null;
        final next = children[index];
        if (next is Map<String, dynamic>) {
          current = next;
        } else {
          return null;
        }
      }
    }

    return current;
  }

  void _appendComponentJson(String json) {
    try {
      final decoded = jsonDecode(json);
      if (decoded is Map<String, dynamic>) {
        _appendSnippet(decoded);
      }
    } catch (_) {}
  }

  void _clearJson() {
    _targetController.text = '{\n  "type": "Container"\n}';
    _validateJson(_targetController.text);
  }

  void _formatJson() {
    try {
      final decoded = jsonDecode(_targetController.text);
      const encoder = JsonEncoder.withIndent('  ');
      _targetController.text = encoder.convert(decoded);
      _validateJson(_targetController.text);
    } catch (_) {
      _validateJson(_targetController.text);
    }
  }

  void _appendSnippet(Map<String, dynamic> snippet) {
    try {
      final decoded = jsonDecode(_targetController.text);
      if (decoded is Map<String, dynamic>) {
        final updated = _appendToFirstChildren(decoded, snippet);
        if (updated != null) {
          const encoder = JsonEncoder.withIndent('  ');
          _targetController.text = encoder.convert(decoded);
          _validateJson(_targetController.text);
          return;
        }
      }
    } catch (_) {}

    _targetController.text = const JsonEncoder.withIndent('  ').convert(snippet);
    _validateJson(_targetController.text);
  }

  Map<String, dynamic>? _appendToFirstChildren(
    Map<String, dynamic> node,
    Map<String, dynamic> snippet,
  ) {
    if (node['children'] is List) {
      final list = node['children'] as List;
      list.add(snippet);
      return node;
    }
    if (node['child'] is Map<String, dynamic>) {
      return _appendToFirstChildren(node['child'] as Map<String, dynamic>, snippet);
    }
    return null;
  }

  void _validateJson(String value) {
    String nextError = '';
    try {
      jsonDecode(value);
    } catch (e) {
      nextError = e.toString();
    }

    if (nextError != _errorText) {
      setState(() => _errorText = nextError);
    } else {
      setState(() {});
    }
  }
}

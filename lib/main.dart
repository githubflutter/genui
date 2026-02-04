import 'dart:convert';

import 'package:flutter/material.dart';

import 'json_runtime_renderer.dart';
import 'json_to_flutter_emitter.dart';

const String uiJson = r'''
{
  "type": "Scaffold",
  "props": {
    "appBar": {"type": "AppBar", "props": {"title": "UiJsonGen"}}
  },
  "child": {
    "type": "Padding",
    "props": {"padding": "EdgeInsets.all(12)"},
    "child": {
      "type": "Column",
      "children": [
        {"type": "Text", "props": {"text": "Edit JSON and preview or export Dart."}},
        {"type": "SizedBox", "props": {"height": 12}},
        {
          "type": "Expanded",
          "child": {
            "type": "Row",
            "children": [
              {
                "type": "Expanded",
                "child": {
                  "type": "Card",
                  "child": {
                    "type": "Padding",
                    "props": {"padding": "EdgeInsets.all(12)"},
                    "child": {
                      "type": "Column",
                      "children": [
                        {"type": "Text", "props": {"text": "JSON"}},
                        {"type": "SizedBox", "props": {"height": 8}},
                        {
                          "type": "Expanded",
                          "child": {
                            "type": "JsonEditor",
                            "props": {
                              "controllerKey": "target",
                              "minLines": 12,
                              "maxLines": 30,
                              "onChanged": "updateTarget"
                            }
                          }
                        },
                        {"type": "SizedBox", "props": {"height": 6}},
                        {"type": "StatusText", "props": {"textKey": "errorText", "color": "red", "fontSize": 12}},
                        {"type": "SizedBox", "props": {"height": 8}},
                        {
                          "type": "Row",
                          "children": [
                            {"type": "Button", "props": {"text": "Master", "onPressed": "loadMaster"}},
                            {"type": "SizedBox", "props": {"width": 8}},
                            {"type": "Button", "props": {"text": "Form", "onPressed": "loadForm"}},
                            {"type": "SizedBox", "props": {"width": 8}},
                            {"type": "Button", "props": {"text": "Format", "onPressed": "formatJson"}},
                            {"type": "SizedBox", "props": {"width": 8}},
                            {"type": "Button", "props": {"text": "Clear", "onPressed": "clearJson"}}
                          ]
                        },
                        {"type": "SizedBox", "props": {"height": 12}},
                        {"type": "Text", "props": {"text": "Palette"}},
                        {"type": "SizedBox", "props": {"height": 6}},
                        {
                          "type": "Row",
                          "children": [
                            {"type": "Button", "props": {"text": "Text", "onPressed": "addText"}},
                            {"type": "SizedBox", "props": {"width": 8}},
                            {"type": "Button", "props": {"text": "Button", "onPressed": "addButton"}},
                            {"type": "SizedBox", "props": {"width": 8}},
                            {"type": "Button", "props": {"text": "Row", "onPressed": "addRow"}},
                            {"type": "SizedBox", "props": {"width": 8}},
                            {"type": "Button", "props": {"text": "Column", "onPressed": "addColumn"}}
                          ]
                        },
                        {"type": "SizedBox", "props": {"height": 8}},
                        {
                          "type": "Row",
                          "children": [
                            {"type": "Button", "props": {"text": "Card", "onPressed": "addCard"}},
                            {"type": "SizedBox", "props": {"width": 8}},
                            {"type": "Button", "props": {"text": "ListView", "onPressed": "addList"}},
                            {"type": "SizedBox", "props": {"width": 8}},
                            {"type": "Button", "props": {"text": "TextField", "onPressed": "addTextField"}},
                            {"type": "SizedBox", "props": {"width": 8}},
                            {"type": "Button", "props": {"text": "Switch", "onPressed": "addSwitch"}}
                          ]
                        }
                      ]
                    }
                  }
                }
              },
              {"type": "SizedBox", "props": {"width": 12}},
              {
                "type": "Expanded",
                "child": {
                  "type": "Card",
                  "child": {
                    "type": "Padding",
                    "props": {"padding": "EdgeInsets.all(12)"},
                    "child": {
                      "type": "Column",
                      "children": [
                        {
                          "type": "Row",
                          "children": [
                            {"type": "Button", "props": {"text": "Preview", "onPressed": "modePreview"}},
                            {"type": "SizedBox", "props": {"width": 8}},
                            {"type": "Button", "props": {"text": "Dart", "onPressed": "modeDart"}}
                          ]
                        },
                        {"type": "SizedBox", "props": {"height": 8}},
                        {"type": "Expanded", "child": {"type": "PreviewPane", "props": {"sourceKey": "target", "modeKey": "previewMode"}}}
                      ]
                    }
                  }
                }
              }
            ]
          }
        }
      ]
    }
  }
}
''';

const String masterDetailJson = r'''
{
  "type": "Scaffold",
  "props": {
    "appBar": {"type": "AppBar", "props": {"title": "Customers"}},
    "drawer": {
      "type": "Drawer",
      "children": [
        {"type": "ListTile", "props": {"title": "Home", "leading": "home", "onTap": "noop"}},
        {"type": "ListTile", "props": {"title": "Settings", "leading": "settings", "onTap": "noop"}}
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
            "onTap": "noop"
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
            "onTap": "noop"
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
        {"type": "TextFormField", "props": {"labelText": "Name"}},
        {"type": "TextFormField", "props": {"labelText": "Email"}},
        {"type": "Switch", "props": {"value": true}},
        {"type": "Button", "props": {"text": "Save", "onPressed": "noop"}}
      ]
    }
  }
}
''';

const Map<String, dynamic> snippetText = {
  'type': 'Text',
  'props': {'text': 'Hello'}
};

const Map<String, dynamic> snippetButton = {
  'type': 'Button',
  'props': {'text': 'Tap', 'onPressed': 'noop'}
};

const Map<String, dynamic> snippetRow = {
  'type': 'Row',
  'children': [
    {'type': 'Text', 'props': {'text': 'Left'}},
    {'type': 'SizedBox', 'props': {'width': 8}},
    {'type': 'Text', 'props': {'text': 'Right'}}
  ]
};

const Map<String, dynamic> snippetColumn = {
  'type': 'Column',
  'children': [
    {'type': 'Text', 'props': {'text': 'Line 1'}},
    {'type': 'Text', 'props': {'text': 'Line 2'}}
  ]
};

const Map<String, dynamic> snippetCard = {
  'type': 'Card',
  'child': {
    'type': 'Padding',
    'props': {'padding': 'EdgeInsets.all(12)'},
    'child': {'type': 'Text', 'props': {'text': 'Card content'}}
  }
};

const Map<String, dynamic> snippetList = {
  'type': 'ListView',
  'children': [
    {'type': 'ListTile', 'props': {'title': 'Item 1'}},
    {'type': 'ListTile', 'props': {'title': 'Item 2'}}
  ]
};

const Map<String, dynamic> snippetTextField = {
  'type': 'TextEdit',
  'props': {'labelText': 'Label'}
};

const Map<String, dynamic> snippetSwitch = {
  'type': 'Switch',
  'props': {'value': true, 'onChanged': 'noop'}
};

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
      home: const UiJsonGenScreen(),
    );
  }
}

class UiJsonGenScreen extends StatefulWidget {
  const UiJsonGenScreen({super.key});

  @override
  State<UiJsonGenScreen> createState() => _UiJsonGenScreenState();
}

class _UiJsonGenScreenState extends State<UiJsonGenScreen> {
  late final TextEditingController _targetController;
  late final JsonWidgetFactory _uiFactory;
  late final JsonWidgetFactory _previewFactory;
  final JsonToFlutterEmitter _emitter = JsonToFlutterEmitter();
  String _errorText = '';
  String _previewMode = 'preview';

  @override
  void initState() {
    super.initState();
    _targetController = TextEditingController(text: masterDetailJson);

    _previewFactory = JsonWidgetFactory(
      actionRegistry: {
        'noop': () {},
      },
    );

    _uiFactory = JsonWidgetFactory(
      actionRegistry: {
        'noop': () {},
        'loadMaster': _loadMaster,
        'loadForm': _loadForm,
        'formatJson': _formatJson,
        'clearJson': _clearJson,
        'addText': () => _appendSnippet(snippetText),
        'addButton': () => _appendSnippet(snippetButton),
        'addRow': () => _appendSnippet(snippetRow),
        'addColumn': () => _appendSnippet(snippetColumn),
        'addCard': () => _appendSnippet(snippetCard),
        'addList': () => _appendSnippet(snippetList),
        'addTextField': () => _appendSnippet(snippetTextField),
        'addSwitch': () => _appendSnippet(snippetSwitch),
        'modePreview': () => _setPreviewMode('preview'),
        'modeDart': () => _setPreviewMode('dart'),
      },
      stringChangedRegistry: {
        'updateTarget': (value) => _validateJson(value),
      },
      controllerRegistry: {
        'target': _targetController,
      },
      jsonResolver: (key) => key == 'target' ? _targetController.text : '',
      textResolver: (key) {
        if (key == 'errorText') return _errorText;
        if (key == 'previewMode') return _previewMode;
        return '';
      },
      previewBuilder: (json) => _buildPreview(json),
      dartPreviewBuilder: (json) => _buildDartPreview(json),
    );

    _validateJson(_targetController.text);
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _uiFactory.buildFromJson(uiJson);
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

  void _setPreviewMode(String mode) {
    setState(() => _previewMode = mode);
  }

  void _loadMaster() {
    _targetController.text = masterDetailJson;
    _validateJson(_targetController.text);
  }

  void _loadForm() {
    _targetController.text = editFormJson;
    _validateJson(_targetController.text);
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

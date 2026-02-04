import 'dart:convert';

import 'package:flutter/material.dart';

/// Runtime JSON -> Widget renderer with parse caching.
///
/// Usage:
///   final factory = JsonWidgetFactory();
///   final widget = factory.buildFromJson(jsonString);
class JsonWidgetFactory {
  JsonWidgetFactory({
    this.enableCache = true,
    Map<String, IconData>? iconRegistry,
    Map<String, VoidCallback>? actionRegistry,
    Map<String, ValueChanged<String>>? stringChangedRegistry,
    Map<String, ValueChanged<bool>>? boolChangedRegistry,
    Map<String, ValueChanged<dynamic>>? dynamicChangedRegistry,
    Map<String, TextEditingController>? controllerRegistry,
    String? Function(String key)? jsonResolver,
    String? Function(String key)? textResolver,
    bool Function(String key)? boolResolver,
    Widget Function(String json)? previewBuilder,
    Widget Function(String json)? dartPreviewBuilder,
  })  : _iconRegistry = iconRegistry ?? _defaultIconRegistry,
        _actionRegistry = actionRegistry ?? const {},
        _stringChangedRegistry = stringChangedRegistry ?? const {},
        _boolChangedRegistry = boolChangedRegistry ?? const {},
        _dynamicChangedRegistry = dynamicChangedRegistry ?? const {},
        _controllerRegistry = controllerRegistry ?? const {},
        _jsonResolver = jsonResolver,
        _textResolver = textResolver,
        _boolResolver = boolResolver,
        _previewBuilder = previewBuilder,
        _dartPreviewBuilder = dartPreviewBuilder;

  final bool enableCache;
  final Map<String, IconData> _iconRegistry;
  final Map<String, VoidCallback> _actionRegistry;
  final Map<String, ValueChanged<String>> _stringChangedRegistry;
  final Map<String, ValueChanged<bool>> _boolChangedRegistry;
  final Map<String, ValueChanged<dynamic>> _dynamicChangedRegistry;
  final Map<String, TextEditingController> _controllerRegistry;
  final String? Function(String key)? _jsonResolver;
  final String? Function(String key)? _textResolver;
  final bool Function(String key)? _boolResolver;
  final Widget Function(String json)? _previewBuilder;
  final Widget Function(String json)? _dartPreviewBuilder;
  final Map<String, Map<String, dynamic>> _parseCache = {};

  Map<String, dynamic> parseJson(String json) {
    if (!enableCache) return jsonDecode(json) as Map<String, dynamic>;
    return _parseCache.putIfAbsent(json, () => jsonDecode(json) as Map<String, dynamic>);
  }

  Widget buildFromJson(String json) {
    final node = parseJson(json);
    return buildFromNode(node);
  }

  Widget buildFromNode(Map<String, dynamic> node) {
    final type = node['type'] as String?;
    final props = (node['props'] as Map?)?.cast<String, dynamic>() ?? {};
    final child = node['child'];
    final children = (node['children'] as List?) ?? const [];

    switch (type) {
      case 'Scaffold':
        return _buildScaffold(props, child, children);
      case 'Text':
      case 'Label':
        return _buildText(props);
      case 'TextEdit':
        return _buildTextField(props);
      case 'TextFormField':
        return _buildTextFormField(props);
      case 'Button':
        return _buildButton(props);
      case 'IconButton':
        return _buildIconButton(props);
      case 'AppBar':
        return _buildAppBar(props);
      case 'BottomAppBar':
        return _buildBottomAppBar(child);
      case 'Drawer':
        return _buildDrawer(child, children);
      case 'ListTile':
        return _buildListTile(props);
      case 'ListView':
        return _buildListView(props, children);
      case 'TableView':
        return _buildDataTable(props);
      case 'DropDown':
        return _buildDropdown(props);
      case 'ScrollView':
        return _buildSingleChildScrollView(props, child);
      case 'NestedScrollView':
        return _buildNestedScrollView(props, child, children);
      case 'Row':
      case 'Column':
        return _buildFlex(type!, props, children);
      case 'Expanded':
      case 'Expended':
        return _buildExpanded(props, child);
      case 'Border':
        return _buildBorder(props);
      case 'Container':
        return _buildContainer(props, child);
      case 'Padding':
        return _buildPadding(props, child);
      case 'SizedBox':
        return _buildSizedBox(props, child);
      case 'Card':
        return _buildCard(props, child);
      case 'Image':
        return _buildImage(props);
      case 'Switch':
        return _buildSwitch(props);
      case 'Checkbox':
        return _buildCheckbox(props);
      case 'Form':
        return _buildForm(props, child, children);
      case 'JsonEditor':
        return _buildJsonEditor(props);
      case 'JsonPreview':
        return _buildJsonPreview(props);
      case 'PreviewPane':
        return _buildPreviewPane(props);
      case 'StatusText':
        return _buildStatusText(props);
      default:
        return _buildGeneric(type ?? 'Container', props, child, children);
    }
  }

  Widget _buildText(Map<String, dynamic> props) {
    final key = props['textKey']?.toString();
    final text = key != null ? (_textResolver?.call(key) ?? '') : (props['text'] ?? props['label'] ?? '');
    return Text(
      text.toString(),
      style: props['style'] is TextStyle ? props['style'] : null,
      textAlign: _textAlignFrom(props['textAlign']),
    );
  }

  Widget _buildTextField(Map<String, dynamic> props) {
    final controllerKey = props['controllerKey']?.toString();
    final controller = controllerKey != null ? _controllerRegistry[controllerKey] : null;
    return TextField(
      controller: controller,
      obscureText: props['obscureText'] == true,
      minLines: props['minLines'] is int ? props['minLines'] as int : null,
      maxLines: props['maxLines'] is int ? props['maxLines'] as int : 1,
      onChanged: _stringCallbackFrom(props['onChanged']),
      decoration: InputDecoration(
        hintText: props['hintText']?.toString(),
        labelText: props['labelText']?.toString(),
      ),
    );
  }

  Widget _buildTextFormField(Map<String, dynamic> props) {
    final controllerKey = props['controllerKey']?.toString();
    final controller = controllerKey != null ? _controllerRegistry[controllerKey] : null;
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? props['initialValue']?.toString() : null,
      obscureText: props['obscureText'] == true,
      minLines: props['minLines'] is int ? props['minLines'] as int : null,
      maxLines: props['maxLines'] is int ? props['maxLines'] as int : 1,
      onChanged: _stringCallbackFrom(props['onChanged']),
      decoration: InputDecoration(
        hintText: props['hintText']?.toString(),
        labelText: props['labelText']?.toString(),
      ),
    );
  }

  Widget _buildButton(Map<String, dynamic> props) {
    final text = props['text'] ?? 'Button';
    return ElevatedButton(
      onPressed: _voidCallbackFrom(props['onPressed']),
      child: Text(text.toString()),
    );
  }

  Widget _buildIconButton(Map<String, dynamic> props) {
    final icon = _iconFrom(props['icon']) ?? Icons.add;
    return IconButton(
      icon: Icon(icon),
      onPressed: _voidCallbackFrom(props['onPressed']),
    );
  }

  PreferredSizeWidget _buildAppBar(Map<String, dynamic> props) {
    final title = props['title'] ?? 'Title';
    return AppBar(
      title: Text(title.toString()),
      centerTitle: props['centerTitle'] == true,
    );
  }

  Widget _buildScaffold(Map<String, dynamic> props, dynamic child, List children) {
    return Scaffold(
      appBar: props['appBar'] is Map<String, dynamic>
          ? buildFromNode(props['appBar'] as Map<String, dynamic>) as PreferredSizeWidget
          : null,
      drawer: props['drawer'] is Map<String, dynamic>
          ? buildFromNode(props['drawer'] as Map<String, dynamic>)
          : null,
      bottomNavigationBar: props['bottomNavigationBar'] is Map<String, dynamic>
          ? buildFromNode(props['bottomNavigationBar'] as Map<String, dynamic>)
          : null,
      floatingActionButton: props['floatingActionButton'] is Map<String, dynamic>
          ? buildFromNode(props['floatingActionButton'] as Map<String, dynamic>)
          : null,
      backgroundColor: props['backgroundColor'] is Color ? props['backgroundColor'] : null,
      body: _buildBody(child, children),
    );
  }

  Widget _buildBody(dynamic child, List children) {
    if (child is Map<String, dynamic>) return buildFromNode(child);
    if (children.isNotEmpty) {
      return Column(
        children: [
          for (final c in children)
            if (c is Map<String, dynamic>) buildFromNode(c),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildBottomAppBar(dynamic child) {
    return BottomAppBar(
      child: child is Map<String, dynamic> ? buildFromNode(child) : null,
    );
  }

  Widget _buildDrawer(dynamic child, List children) {
    if (child is Map<String, dynamic>) return Drawer(child: buildFromNode(child));
    if (children.isNotEmpty) {
      return Drawer(
        child: ListView(
          children: [
            for (final c in children)
              if (c is Map<String, dynamic>) buildFromNode(c),
          ],
        ),
      );
    }
    return const Drawer();
  }

  Widget _buildListTile(Map<String, dynamic> props) {
    return ListTile(
      leading: _widgetOrIcon(props['leading']),
      title: props['title'] is Widget
          ? props['title']
          : Text(props['title']?.toString() ?? ''),
      subtitle: props['subtitle'] is Widget
          ? props['subtitle']
          : (props['subtitle'] != null ? Text(props['subtitle'].toString()) : null),
      trailing: _widgetOrIcon(props['trailing']),
      onTap: _voidCallbackFrom(props['onTap']),
    );
  }

  Widget _buildListView(Map<String, dynamic> props, List children) {
    return ListView(
      scrollDirection: _axisFrom(props['scrollDirection']) ?? Axis.vertical,
      padding: _edgeInsetsFrom(props['padding']),
      children: [
        for (final c in children)
          if (c is Map<String, dynamic>) buildFromNode(c),
      ],
    );
  }

  Widget _buildDataTable(Map<String, dynamic> props) {
    final columns = (props['columns'] as List?) ?? const [];
    final rows = (props['rows'] as List?) ?? const [];
    return DataTable(
      columns: [
        for (final c in columns) DataColumn(label: Text(c.toString())),
      ],
      rows: [
        for (final r in rows)
          if (r is List)
            DataRow(
              cells: [
                for (final cell in r) DataCell(Text(cell.toString())),
              ],
            ),
      ],
    );
  }

  Widget _buildDropdown(Map<String, dynamic> props) {
    final items = (props['items'] as List?) ?? const [];
    final value = props['value'];
    return DropdownButton(
      value: value,
      onChanged: _dynamicCallbackFrom(props['onChanged']) ?? (v) {},
      items: [
        for (final i in items)
          DropdownMenuItem(value: i, child: Text(i.toString())),
      ],
    );
  }

  Widget _buildSingleChildScrollView(Map<String, dynamic> props, dynamic child) {
    return SingleChildScrollView(
      scrollDirection: _axisFrom(props['scrollDirection']) ?? Axis.vertical,
      child: child is Map<String, dynamic> ? buildFromNode(child) : null,
    );
  }

  Widget _buildNestedScrollView(Map<String, dynamic> props, dynamic child, List children) {
    final header = props['headerSliver'];
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        if (header is Map<String, dynamic>) buildFromNode(header),
      ],
      body: child is Map<String, dynamic>
          ? buildFromNode(child)
          : Column(
              children: [
                for (final c in children)
                  if (c is Map<String, dynamic>) buildFromNode(c),
              ],
            ),
    );
  }

  Widget _buildFlex(String type, Map<String, dynamic> props, List children) {
    final mainAxis = _mainAxisAlignmentFrom(props['mainAxisAlignment']) ?? MainAxisAlignment.start;
    final crossAxis = _crossAxisAlignmentFrom(props['crossAxisAlignment']) ?? CrossAxisAlignment.center;

    final kids = [
      for (final c in children)
        if (c is Map<String, dynamic>) buildFromNode(c),
    ];

    return type == 'Row'
        ? Row(mainAxisAlignment: mainAxis, crossAxisAlignment: crossAxis, children: kids)
        : Column(mainAxisAlignment: mainAxis, crossAxisAlignment: crossAxis, children: kids);
  }

  Widget _buildExpanded(Map<String, dynamic> props, dynamic child) {
    return Expanded(
      flex: props['flex'] is int ? props['flex'] as int : 1,
      child: child is Map<String, dynamic> ? buildFromNode(child) : const SizedBox.shrink(),
    );
  }

  Widget _buildBorder(Map<String, dynamic> props) {
    final color = _colorFrom(props['color']) ?? Colors.black;
    final width = props['width'] is num ? (props['width'] as num).toDouble() : 1.0;
    return Container(decoration: BoxDecoration(border: Border.all(color: color, width: width)));
  }

  Widget _buildContainer(Map<String, dynamic> props, dynamic child) {
    return Container(
      padding: _edgeInsetsFrom(props['padding']),
      margin: _edgeInsetsFrom(props['margin']),
      color: _colorFrom(props['color']),
      decoration: props['decoration'] is Decoration ? props['decoration'] as Decoration : null,
      child: child is Map<String, dynamic> ? buildFromNode(child) : null,
    );
  }

  Widget _buildPadding(Map<String, dynamic> props, dynamic child) {
    return Padding(
      padding: _edgeInsetsFrom(props['padding']) ?? EdgeInsets.zero,
      child: child is Map<String, dynamic> ? buildFromNode(child) : const SizedBox.shrink(),
    );
  }

  Widget _buildSizedBox(Map<String, dynamic> props, dynamic child) {
    return SizedBox(
      width: props['width'] is num ? (props['width'] as num).toDouble() : null,
      height: props['height'] is num ? (props['height'] as num).toDouble() : null,
      child: child is Map<String, dynamic> ? buildFromNode(child) : null,
    );
  }

  Widget _buildCard(Map<String, dynamic> props, dynamic child) {
    return Card(
      elevation: props['elevation'] is num ? (props['elevation'] as num).toDouble() : null,
      margin: _edgeInsetsFrom(props['margin']),
      child: child is Map<String, dynamic> ? buildFromNode(child) : null,
    );
  }

  Widget _buildImage(Map<String, dynamic> props) {
    final source = props['source']?.toString() ?? '';
    final fit = _boxFitFrom(props['fit']);
    final width = props['width'] is num ? (props['width'] as num).toDouble() : null;
    final height = props['height'] is num ? (props['height'] as num).toDouble() : null;
    if (props['network'] == true) {
      return Image.network(source, fit: fit, width: width, height: height);
    }
    return Image.asset(source, fit: fit, width: width, height: height);
  }

  Widget _buildSwitch(Map<String, dynamic> props) {
    return Switch(
      value: props['value'] == true,
      onChanged: _boolCallbackFrom(props['onChanged']) ?? (v) {},
    );
  }

  Widget _buildCheckbox(Map<String, dynamic> props) {
    return Checkbox(
      value: props['value'] == true,
      onChanged: (v) {
        final cb = _boolCallbackFrom(props['onChanged']);
        if (cb != null && v != null) cb(v);
      },
    );
  }

  Widget _buildForm(Map<String, dynamic> props, dynamic child, List children) {
    return Form(
      key: props['key'] is GlobalKey<FormState> ? props['key'] as GlobalKey<FormState> : null,
      child: child is Map<String, dynamic>
          ? buildFromNode(child)
          : Column(
              children: [
                for (final c in children)
                  if (c is Map<String, dynamic>) buildFromNode(c),
              ],
            ),
    );
  }

  Widget _buildGeneric(String type, Map<String, dynamic> props, dynamic child, List children) {
    return Container(
      child: child is Map<String, dynamic>
          ? buildFromNode(child)
          : Column(
              children: [
                for (final c in children)
                  if (c is Map<String, dynamic>) buildFromNode(c),
              ],
            ),
    );
  }

  Widget? _widgetOrIcon(dynamic value) {
    if (value is Widget) return value;
    if (value is Map<String, dynamic>) return buildFromNode(value);
    final icon = _iconFrom(value);
    if (icon != null) return Icon(icon);
    return null;
  }

  VoidCallback? _voidCallbackFrom(dynamic value) {
    if (value is VoidCallback) return value;
    if (value is String) return _actionRegistry[value];
    return null;
  }

  ValueChanged<String>? _stringCallbackFrom(dynamic value) {
    if (value is ValueChanged<String>) return value;
    if (value is String) return _stringChangedRegistry[value];
    return null;
  }

  ValueChanged<bool>? _boolCallbackFrom(dynamic value) {
    if (value is ValueChanged<bool>) return value;
    if (value is String) return _boolChangedRegistry[value];
    return null;
  }

  ValueChanged<dynamic>? _dynamicCallbackFrom(dynamic value) {
    if (value is ValueChanged<dynamic>) return value;
    if (value is String) return _dynamicChangedRegistry[value];
    return null;
  }

  Widget _buildJsonEditor(Map<String, dynamic> props) {
    final controllerKey = props['controllerKey']?.toString();
    final controller = controllerKey != null ? _controllerRegistry[controllerKey] : null;
    return TextField(
      controller: controller,
      minLines: props['minLines'] is int ? props['minLines'] as int : 8,
      maxLines: props['maxLines'] is int ? props['maxLines'] as int : 20,
      onChanged: _stringCallbackFrom(props['onChanged']),
      decoration: InputDecoration(
        labelText: props['labelText']?.toString() ?? 'JSON',
        hintText: props['hintText']?.toString(),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildJsonPreview(Map<String, dynamic> props) {
    final key = props['sourceKey']?.toString() ?? '';
    final json = _jsonResolver?.call(key) ?? '';
    if (json.trim().isEmpty) {
      return const Center(child: Text('No JSON'));
    }
    try {
      if (_previewBuilder != null) return _previewBuilder!(json);
      return buildFromJson(json);
    } catch (e) {
      return Center(
        child: Text('Invalid JSON: $e', textAlign: TextAlign.center),
      );
    }
  }

  Widget _buildPreviewPane(Map<String, dynamic> props) {
    final key = props['sourceKey']?.toString() ?? '';
    final modeKey = props['modeKey']?.toString() ?? '';
    final mode = modeKey.isEmpty ? 'json' : (_textResolver?.call(modeKey) ?? 'json');
    final json = _jsonResolver?.call(key) ?? '';
    if (json.trim().isEmpty) {
      return const Center(child: Text('No JSON'));
    }
    try {
      if (mode == 'dart' && _dartPreviewBuilder != null) return _dartPreviewBuilder!(json);
      if (_previewBuilder != null) return _previewBuilder!(json);
      return buildFromJson(json);
    } catch (e) {
      return Center(child: Text('Invalid JSON: $e', textAlign: TextAlign.center));
    }
  }

  Widget _buildStatusText(Map<String, dynamic> props) {
    final key = props['textKey']?.toString() ?? '';
    final text = _textResolver?.call(key) ?? '';
    if (text.isEmpty) return const SizedBox.shrink();
    return Text(
      text,
      style: TextStyle(
        color: _colorFrom(props['color']) ?? Colors.red,
        fontSize: props['fontSize'] is num ? (props['fontSize'] as num).toDouble() : 12.0,
      ),
    );
  }
}

Color? _colorFrom(dynamic value) {
  if (value is Color) return value;
  if (value is String) {
    if (value.startsWith('#')) {
      final hex = value.substring(1);
      final intVal = int.tryParse(hex, radix: 16);
      if (intVal != null) {
        final argb = hex.length <= 6 ? (0xFF000000 | intVal) : intVal;
        return Color(argb);
      }
    }
    if (value.startsWith('0x')) {
      final intVal = int.tryParse(value.substring(2), radix: 16);
      if (intVal != null) return Color(intVal);
    }
    final lower = value.toLowerCase();
    const named = {
      'red': Colors.red,
      'green': Colors.green,
      'blue': Colors.blue,
      'black': Colors.black,
      'white': Colors.white,
      'grey': Colors.grey,
      'gray': Colors.grey,
      'amber': Colors.amber,
      'orange': Colors.orange,
      'purple': Colors.purple,
    };
    return named[lower];
  }
  return null;
}

Axis? _axisFrom(dynamic value) {
  if (value is Axis) return value;
  if (value is String) {
    switch (value.toLowerCase()) {
      case 'horizontal':
        return Axis.horizontal;
      case 'vertical':
        return Axis.vertical;
    }
  }
  return null;
}

MainAxisAlignment? _mainAxisAlignmentFrom(dynamic value) {
  if (value is MainAxisAlignment) return value;
  if (value is String) {
    switch (value.toLowerCase()) {
      case 'start':
        return MainAxisAlignment.start;
      case 'end':
        return MainAxisAlignment.end;
      case 'center':
        return MainAxisAlignment.center;
      case 'spacebetween':
      case 'space_between':
        return MainAxisAlignment.spaceBetween;
      case 'spacearound':
      case 'space_around':
        return MainAxisAlignment.spaceAround;
      case 'spaceevenly':
      case 'space_evenly':
        return MainAxisAlignment.spaceEvenly;
    }
  }
  return null;
}

CrossAxisAlignment? _crossAxisAlignmentFrom(dynamic value) {
  if (value is CrossAxisAlignment) return value;
  if (value is String) {
    switch (value.toLowerCase()) {
      case 'start':
        return CrossAxisAlignment.start;
      case 'end':
        return CrossAxisAlignment.end;
      case 'center':
        return CrossAxisAlignment.center;
      case 'stretch':
        return CrossAxisAlignment.stretch;
      case 'baseline':
        return CrossAxisAlignment.baseline;
    }
  }
  return null;
}

TextAlign? _textAlignFrom(dynamic value) {
  if (value is TextAlign) return value;
  if (value is String) {
    switch (value.toLowerCase()) {
      case 'start':
        return TextAlign.start;
      case 'end':
        return TextAlign.end;
      case 'center':
        return TextAlign.center;
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      case 'justify':
        return TextAlign.justify;
    }
  }
  return null;
}

BoxFit? _boxFitFrom(dynamic value) {
  if (value is BoxFit) return value;
  if (value is String) {
    switch (value.toLowerCase()) {
      case 'cover':
        return BoxFit.cover;
      case 'contain':
        return BoxFit.contain;
      case 'fill':
        return BoxFit.fill;
      case 'fitwidth':
      case 'fit_width':
        return BoxFit.fitWidth;
      case 'fitheight':
      case 'fit_height':
        return BoxFit.fitHeight;
      case 'none':
        return BoxFit.none;
      case 'scalexdown':
      case 'scale_down':
        return BoxFit.scaleDown;
    }
  }
  return null;
}

EdgeInsets? _edgeInsetsFrom(dynamic value) {
  if (value is EdgeInsets) return value;
  if (value is String) {
    final all = RegExp(r'^EdgeInsets\\.all\\((.+)\\)$').firstMatch(value);
    if (all != null) {
      final v = double.tryParse(all.group(1)!.trim());
      if (v != null) return EdgeInsets.all(v);
    }
    final symmetric = RegExp(r'^EdgeInsets\\.symmetric\\((.+)\\)$').firstMatch(value);
    if (symmetric != null) {
      final body = symmetric.group(1)!;
      final h = _extractNamedDouble(body, 'horizontal') ?? 0.0;
      final v = _extractNamedDouble(body, 'vertical') ?? 0.0;
      return EdgeInsets.symmetric(horizontal: h, vertical: v);
    }
    final ltrb = RegExp(r'^EdgeInsets\\.fromLTRB\\((.+)\\)$').firstMatch(value);
    if (ltrb != null) {
      final parts = ltrb.group(1)!.split(',').map((e) => e.trim()).toList();
      if (parts.length == 4) {
        final left = double.tryParse(parts[0]) ?? 0.0;
        final top = double.tryParse(parts[1]) ?? 0.0;
        final right = double.tryParse(parts[2]) ?? 0.0;
        final bottom = double.tryParse(parts[3]) ?? 0.0;
        return EdgeInsets.fromLTRB(left, top, right, bottom);
      }
    }
  }
  if (value is Map<String, dynamic>) {
    if (value.containsKey('all')) {
      final v = (value['all'] as num).toDouble();
      return EdgeInsets.all(v);
    }
    if (value.containsKey('horizontal') || value.containsKey('vertical')) {
      final h = (value['horizontal'] as num?)?.toDouble() ?? 0.0;
      final v = (value['vertical'] as num?)?.toDouble() ?? 0.0;
      return EdgeInsets.symmetric(horizontal: h, vertical: v);
    }
    final left = (value['left'] as num?)?.toDouble() ?? 0.0;
    final top = (value['top'] as num?)?.toDouble() ?? 0.0;
    final right = (value['right'] as num?)?.toDouble() ?? 0.0;
    final bottom = (value['bottom'] as num?)?.toDouble() ?? 0.0;
    return EdgeInsets.fromLTRB(left, top, right, bottom);
  }
  return null;
}

double? _extractNamedDouble(String body, String name) {
  final match = RegExp('$name\\s*:\\s*([0-9\\.]+)').firstMatch(body);
  if (match == null) return null;
  return double.tryParse(match.group(1)!);
}

IconData? _iconFrom(dynamic value) {
  if (value is IconData) return value;
  if (value is String) {
    final key = value.startsWith('Icons.') ? value.substring(6) : value;
    return _defaultIconRegistry[key] ?? _defaultIconRegistry[value];
  }
  return null;
}

const Map<String, IconData> _defaultIconRegistry = {
  'add': Icons.add,
  'edit': Icons.edit,
  'delete': Icons.delete,
  'menu': Icons.menu,
  'home': Icons.home,
  'settings': Icons.settings,
  'arrow_back': Icons.arrow_back,
  'arrow_forward': Icons.arrow_forward,
  'search': Icons.search,
};

class JsonBuildBenchmarkResult {
  JsonBuildBenchmarkResult({
    required this.iterations,
    required this.parseAndBuildMicros,
    required this.buildOnlyMicros,
  });

  final int iterations;
  final int parseAndBuildMicros;
  final int buildOnlyMicros;
}

JsonBuildBenchmarkResult benchmarkJsonBuild({
  required String json,
  int iterations = 200,
}) {
  final factory = JsonWidgetFactory();
  final swParse = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    factory.buildFromJson(json);
  }
  swParse.stop();

  final node = factory.parseJson(json);
  final swBuild = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    factory.buildFromNode(node);
  }
  swBuild.stop();

  return JsonBuildBenchmarkResult(
    iterations: iterations,
    parseAndBuildMicros: swParse.elapsedMicroseconds,
    buildOnlyMicros: swBuild.elapsedMicroseconds,
  );
}

class JsonBenchmarkScreen extends StatelessWidget {
  const JsonBenchmarkScreen({super.key, required this.json});

  final String json;

  @override
  Widget build(BuildContext context) {
    final result = benchmarkJsonBuild(json: json);
    final parseMs = result.parseAndBuildMicros / 1000.0;
    final buildMs = result.buildOnlyMicros / 1000.0;

    return Scaffold(
      appBar: AppBar(title: const Text('JSON UI Benchmark')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Iterations: ${result.iterations}'),
            Text('Parse + build: ${parseMs.toStringAsFixed(2)} ms'),
            Text('Build only (cached parse): ${buildMs.toStringAsFixed(2)} ms'),
          ],
        ),
      ),
    );
  }
}

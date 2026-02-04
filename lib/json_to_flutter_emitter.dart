import 'dart:convert';

class JsonToFlutterEmitter {
  final Map<int, String> _nodeCache = {};

  String emitFromJson(String json) {
    final data = jsonDecode(json);
    return emitWidget(data);
  }

  String emitWidget(dynamic node, {int indent = 0}) {
    if (node is Map<String, dynamic>) {
      final key = identityHashCode(node);
      final cached = _nodeCache[key];
      if (cached != null) return _indent(indent) + cached.trimLeft();
    }

    if (node is! Map<String, dynamic>) {
      return _indent(indent) + _emitLiteral(node) + ',';
    }

    final type = node['type'] as String?;
    if (type == null) return _indent(indent) + '/* missing type */';

    final props = (node['props'] as Map?)?.cast<String, dynamic>() ?? {};
    final child = node['child'];
    final children = (node['children'] as List?) ?? const [];

    String result;
    switch (type) {
      case 'Scaffold':
        result = _emitScaffold(props, indent, child, children);
        break;
      case 'Text':
      case 'Label':
        result = _emitText(type, props, indent);
        break;
      case 'TextEdit':
        result = _emitTextField(props, indent);
        break;
      case 'TextFormField':
        result = _emitTextFormField(props, indent);
        break;
      case 'Button':
        result = _emitButton(props, indent);
        break;
      case 'IconButton':
        result = _emitIconButton(props, indent);
        break;
      case 'AppBar':
        result = _emitAppBar(props, indent);
        break;
      case 'BottomAppBar':
        result = _emitBottomAppBar(props, indent, child);
        break;
      case 'Drawer':
        result = _emitDrawer(props, indent, child, children);
        break;
      case 'ListTile':
        result = _emitListTile(props, indent);
        break;
      case 'ListView':
        result = _emitListView(props, indent, children);
        break;
      case 'TableView':
        result = _emitDataTable(props, indent);
        break;
      case 'DropDown':
        result = _emitDropdown(props, indent);
        break;
      case 'ScrollView':
        result = _emitSingleChildScrollView(props, indent, child);
        break;
      case 'NestedScrollView':
        result = _emitNestedScrollView(props, indent, child, children);
        break;
      case 'Row':
      case 'Column':
        result = _emitFlex(type, props, indent, children);
        break;
      case 'Expanded':
      case 'Expended':
        result = _emitExpanded(props, indent, child);
        break;
      case 'Border':
        result = _emitBorder(props, indent);
        break;
      case 'Container':
        result = _emitContainer(props, indent, child);
        break;
      case 'Padding':
        result = _emitPadding(props, indent, child);
        break;
      case 'SizedBox':
        result = _emitSizedBox(props, indent, child);
        break;
      case 'Card':
        result = _emitCard(props, indent, child);
        break;
      case 'Image':
        result = _emitImage(props, indent);
        break;
      case 'Switch':
        result = _emitSwitch(props, indent);
        break;
      case 'Checkbox':
        result = _emitCheckbox(props, indent);
        break;
      case 'Form':
        result = _emitForm(props, indent, child, children);
        break;
      default:
        result = _emitGeneric(type, props, indent, child, children);
        break;
    }

    final key = identityHashCode(node);
    _nodeCache[key] = result.trimLeft();
    return result;
  }

  String _emitText(String type, Map<String, dynamic> props, int indent) {
    final text = props['text'] ?? props['label'] ?? '';
    final style = props['style'];
    final align = props['textAlign'];
    final buf = StringBuffer();
    buf.write(_indent(indent));
    buf.write('Text(');
    buf.write(_emitLiteral(text));
    if (style != null) {
      buf.write(', style: ${_emitLiteral(style)}');
    }
    if (align != null) {
      buf.write(', textAlign: ${_emitLiteral(align)}');
    }
    buf.write('),');
    return buf.toString();
  }

  String _emitTextField(Map<String, dynamic> props, int indent) {
    final hint = props['hintText'];
    final label = props['labelText'];
    final obscure = props['obscureText'];
    final buf = StringBuffer();
    buf.write(_indent(indent));
    buf.write('TextField(');
    if (obscure != null) buf.write('obscureText: ${_emitLiteral(obscure)}, ');
    if (hint != null || label != null) {
      buf.write('decoration: InputDecoration(');
      if (hint != null) buf.write('hintText: ${_emitLiteral(hint)}, ');
      if (label != null) buf.write('labelText: ${_emitLiteral(label)}, ');
      buf.write('), ');
    }
    buf.write('),');
    return buf.toString();
  }

  String _emitTextFormField(Map<String, dynamic> props, int indent) {
    final hint = props['hintText'];
    final label = props['labelText'];
    final obscure = props['obscureText'];
    final validator = props['validator'];
    final buf = StringBuffer();
    buf.write(_indent(indent));
    buf.write('TextFormField(');
    if (obscure != null) buf.write('obscureText: ${_emitLiteral(obscure)}, ');
    if (validator != null) buf.write('validator: ${_emitLiteral(validator)}, ');
    if (hint != null || label != null) {
      buf.write('decoration: InputDecoration(');
      if (hint != null) buf.write('hintText: ${_emitLiteral(hint)}, ');
      if (label != null) buf.write('labelText: ${_emitLiteral(label)}, ');
      buf.write('), ');
    }
    buf.write('),');
    return buf.toString();
  }

  String _emitButton(Map<String, dynamic> props, int indent) {
    final text = props['text'] ?? 'Button';
    final onPressed = props['onPressed'] ?? '() {}';
    return _indent(indent) +
        'ElevatedButton(onPressed: ${_emitLiteral(onPressed)}, child: Text(${_emitLiteral(text)})),';
  }

  String _emitIconButton(Map<String, dynamic> props, int indent) {
    final icon = props['icon'] ?? 'Icons.add';
    final onPressed = props['onPressed'] ?? '() {}';
    return _indent(indent) +
        'IconButton(icon: ${_emitLiteral(icon)}, onPressed: ${_emitLiteral(onPressed)}),';
  }

  String _emitAppBar(Map<String, dynamic> props, int indent) {
    final title = props['title'] ?? 'Title';
    final centerTitle = props['centerTitle'];
    final buf = StringBuffer();
    buf.write(_indent(indent));
    buf.write('AppBar(');
    buf.write('title: Text(${_emitLiteral(title)}), ');
    if (centerTitle != null) buf.write('centerTitle: ${_emitLiteral(centerTitle)}, ');
    buf.write('),');
    return buf.toString();
  }

  String _emitScaffold(Map<String, dynamic> props, int indent, dynamic child, List children) {
    final appBar = props['appBar'];
    final drawer = props['drawer'];
    final bottomNavigationBar = props['bottomNavigationBar'];
    final floatingActionButton = props['floatingActionButton'];
    final backgroundColor = props['backgroundColor'];
    final buf = StringBuffer();
    buf.write(_indent(indent));
    buf.write('Scaffold(');
    if (appBar != null) {
      buf.write('\n${_indent(indent + 2)}appBar: ');
      buf.write('\n${emitWidget(appBar, indent: indent + 4)}');
      buf.write(',');
    }
    if (drawer != null) {
      buf.write('\n${_indent(indent + 2)}drawer: ');
      buf.write('\n${emitWidget(drawer, indent: indent + 4)}');
      buf.write(',');
    }
    if (bottomNavigationBar != null) {
      buf.write('\n${_indent(indent + 2)}bottomNavigationBar: ');
      buf.write('\n${emitWidget(bottomNavigationBar, indent: indent + 4)}');
      buf.write(',');
    }
    if (floatingActionButton != null) {
      buf.write('\n${_indent(indent + 2)}floatingActionButton: ');
      buf.write('\n${emitWidget(floatingActionButton, indent: indent + 4)}');
      buf.write(',');
    }
    if (backgroundColor != null) {
      buf.write('\n${_indent(indent + 2)}backgroundColor: ${_emitLiteral(backgroundColor)},');
    }
    if (child != null) {
      buf.write('\n${_indent(indent + 2)}body: ');
      buf.write('\n${emitWidget(child, indent: indent + 4)}');
      buf.write(',');
    } else if (children.isNotEmpty) {
      buf.write('\n${_indent(indent + 2)}body: Column(');
      buf.write('\n${_indent(indent + 4)}children: [\n');
      for (final c in children) {
        buf.write(emitWidget(c, indent: indent + 6));
        buf.write('\n');
      }
      buf.write('${_indent(indent + 4)}],');
      buf.write('\n${_indent(indent + 2)}),');
    }
    buf.write('\n${_indent(indent)}),');
    return buf.toString();
  }

  String _emitBottomAppBar(Map<String, dynamic> props, int indent, dynamic child) {
    final buf = StringBuffer();
    buf.write(_indent(indent));
    buf.write('BottomAppBar(');
    if (child != null) {
      buf.write('child: ');
      buf.write('\n${emitWidget(child, indent: indent + 2)}');
      buf.write('\n${_indent(indent)}');
    }
    buf.write('),');
    return buf.toString();
  }

  String _emitDrawer(Map<String, dynamic> props, int indent, dynamic child, List children) {
    final buf = StringBuffer();
    buf.write(_indent(indent));
    buf.write('Drawer(');
    if (child != null) {
      buf.write('child: ');
      buf.write('\n${emitWidget(child, indent: indent + 2)}');
      buf.write('\n${_indent(indent)}');
    } else if (children.isNotEmpty) {
      buf.write('child: ListView(');
      buf.write('\n${_indent(indent + 2)}children: [\n');
      for (final c in children) {
        buf.write(emitWidget(c, indent: indent + 4));
        buf.write('\n');
      }
      buf.write('${_indent(indent + 2)}],');
      buf.write('\n${_indent(indent)}');
      buf.write('),');
    }
    buf.write('),');
    return buf.toString();
  }

  String _emitListTile(Map<String, dynamic> props, int indent) {
    final title = props['title'];
    final subtitle = props['subtitle'];
    final leading = props['leading'];
    final trailing = props['trailing'];
    final onTap = props['onTap'];
    final buf = StringBuffer();
    buf.write(_indent(indent));
    buf.write('ListTile(');
    if (leading != null) {
      buf.write('leading: ${_emitLiteral(leading)}, ');
    }
    if (title != null) {
      buf.write('title: ${_emitLiteral(title)}, ');
    }
    if (subtitle != null) {
      buf.write('subtitle: ${_emitLiteral(subtitle)}, ');
    }
    if (trailing != null) {
      buf.write('trailing: ${_emitLiteral(trailing)}, ');
    }
    if (onTap != null) {
      buf.write('onTap: ${_emitLiteral(onTap)}, ');
    }
    buf.write('),');
    return buf.toString();
  }

  String _emitListView(Map<String, dynamic> props, int indent, List children) {
    final scrollDirection = props['scrollDirection'];
    final padding = props['padding'];
    final buf = StringBuffer();
    buf.write(_indent(indent));
    buf.write('ListView(');
    if (scrollDirection != null) buf.write('scrollDirection: ${_emitLiteral(scrollDirection)}, ');
    if (padding != null) buf.write('padding: ${_emitLiteral(padding)}, ');
    buf.write('\n${_indent(indent + 2)}children: [\n');
    for (final c in children) {
      buf.write(emitWidget(c, indent: indent + 4));
      buf.write('\n');
    }
    buf.write('${_indent(indent + 2)}],');
    buf.write('\n${_indent(indent)}');
    buf.write('),');
    return buf.toString();
  }

  String _emitDataTable(Map<String, dynamic> props, int indent) {
    final columns = (props['columns'] as List?) ?? [];
    final rows = (props['rows'] as List?) ?? [];
    final buf = StringBuffer();
    buf.write(_indent(indent));
    buf.write('DataTable(');
    buf.write('\n${_indent(indent + 2)}columns: [\n');
    for (final c in columns) {
      buf.write('${_indent(indent + 4)}DataColumn(label: Text(${_emitLiteral(c)})),\n');
    }
    buf.write('${_indent(indent + 2)}],\n');
    buf.write('${_indent(indent + 2)}rows: [\n');
    for (final r in rows) {
      if (r is List) {
        buf.write('${_indent(indent + 4)}DataRow(cells: [\n');
        for (final cell in r) {
          buf.write('${_indent(indent + 6)}DataCell(Text(${_emitLiteral(cell)})),\n');
        }
        buf.write('${_indent(indent + 4)}]),\n');
      }
    }
    buf.write('${_indent(indent + 2)}],\n');
    buf.write('${_indent(indent)}),');
    return buf.toString();
  }

  String _emitDropdown(Map<String, dynamic> props, int indent) {
    final items = (props['items'] as List?) ?? [];
    final value = props['value'];
    final onChanged = props['onChanged'] ?? '(v) {}';
    final buf = StringBuffer();
    buf.write(_indent(indent));
    buf.write('DropdownButton(');
    if (value != null) buf.write('value: ${_emitLiteral(value)}, ');
    buf.write('onChanged: ${_emitLiteral(onChanged)}, ');
    buf.write('\n${_indent(indent + 2)}items: [\n');
    for (final i in items) {
      buf.write('${_indent(indent + 4)}DropdownMenuItem(value: ${_emitLiteral(i)}, child: Text(${_emitLiteral(i)})),\n');
    }
    buf.write('${_indent(indent + 2)}],\n');
    buf.write('${_indent(indent)}),');
    return buf.toString();
  }

  String _emitSingleChildScrollView(Map<String, dynamic> props, int indent, dynamic child) {
    final scrollDirection = props['scrollDirection'];
    final buf = StringBuffer();
    buf.write(_indent(indent));
    buf.write('SingleChildScrollView(');
    if (scrollDirection != null) buf.write('scrollDirection: ${_emitLiteral(scrollDirection)}, ');
    if (child != null) {
      buf.write('child: ');
      buf.write('\n${emitWidget(child, indent: indent + 2)}');
      buf.write('\n${_indent(indent)}');
    }
    buf.write('),');
    return buf.toString();
  }

  String _emitNestedScrollView(Map<String, dynamic> props, int indent, dynamic child, List children) {
    final header = props['headerSliver'];
    final buf = StringBuffer();
    buf.write(_indent(indent));
    buf.write('NestedScrollView(');
    if (header != null) {
      buf.write('headerSliverBuilder: (context, innerBoxIsScrolled) => [\n');
      buf.write(emitWidget(header, indent: indent + 2));
      buf.write('\n${_indent(indent)}], ');
    }
    if (child != null) {
      buf.write('body: ');
      buf.write('\n${emitWidget(child, indent: indent + 2)}');
      buf.write('\n${_indent(indent)}');
    } else if (children.isNotEmpty) {
      buf.write('body: Column(');
      buf.write('\n${_indent(indent + 2)}children: [\n');
      for (final c in children) {
        buf.write(emitWidget(c, indent: indent + 4));
        buf.write('\n');
      }
      buf.write('${_indent(indent + 2)}],');
      buf.write('\n${_indent(indent)}');
      buf.write('),');
    }
    buf.write('),');
    return buf.toString();
  }

  String _emitFlex(String type, Map<String, dynamic> props, int indent, List children) {
    final mainAxis = props['mainAxisAlignment'];
    final crossAxis = props['crossAxisAlignment'];
    final buf = StringBuffer();
    buf.write(_indent(indent));
    buf.write('$type(');
    if (mainAxis != null) buf.write('mainAxisAlignment: ${_emitLiteral(mainAxis)}, ');
    if (crossAxis != null) buf.write('crossAxisAlignment: ${_emitLiteral(crossAxis)}, ');
    buf.write('\n${_indent(indent + 2)}children: [\n');
    for (final c in children) {
      buf.write(emitWidget(c, indent: indent + 4));
      buf.write('\n');
    }
    buf.write('${_indent(indent + 2)}],');
    buf.write('\n${_indent(indent)}');
    buf.write('),');
    return buf.toString();
  }

  String _emitExpanded(Map<String, dynamic> props, int indent, dynamic child) {
    final flex = props['flex'];
    final buf = StringBuffer();
    buf.write(_indent(indent));
    buf.write('Expanded(');
    if (flex != null) buf.write('flex: ${_emitLiteral(flex)}, ');
    if (child != null) {
      buf.write('child: ');
      buf.write('\n${emitWidget(child, indent: indent + 2)}');
      buf.write('\n${_indent(indent)}');
    }
    buf.write('),');
    return buf.toString();
  }

  String _emitBorder(Map<String, dynamic> props, int indent) {
    final color = props['color'] ?? 'Colors.black';
    final width = props['width'] ?? 1;
    return _indent(indent) + 'Border.all(color: ${_emitLiteral(color)}, width: ${_emitLiteral(width)}),';
  }

  String _emitContainer(Map<String, dynamic> props, int indent, dynamic child) {
    final padding = props['padding'];
    final margin = props['margin'];
    final color = props['color'];
    final decoration = props['decoration'];
    final buf = StringBuffer();
    buf.write(_indent(indent));
    buf.write('Container(');
    if (padding != null) buf.write('padding: ${_emitLiteral(padding)}, ');
    if (margin != null) buf.write('margin: ${_emitLiteral(margin)}, ');
    if (color != null) buf.write('color: ${_emitLiteral(color)}, ');
    if (decoration != null) buf.write('decoration: ${_emitLiteral(decoration)}, ');
    if (child != null) {
      buf.write('child: ');
      buf.write('\n${emitWidget(child, indent: indent + 2)}');
      buf.write('\n${_indent(indent)}');
    }
    buf.write('),');
    return buf.toString();
  }

  String _emitPadding(Map<String, dynamic> props, int indent, dynamic child) {
    final padding = props['padding'] ?? 'EdgeInsets.zero';
    final buf = StringBuffer();
    buf.write(_indent(indent));
    buf.write('Padding(');
    buf.write('padding: ${_emitLiteral(padding)}, ');
    if (child != null) {
      buf.write('child: ');
      buf.write('\n${emitWidget(child, indent: indent + 2)}');
      buf.write('\n${_indent(indent)}');
    }
    buf.write('),');
    return buf.toString();
  }

  String _emitSizedBox(Map<String, dynamic> props, int indent, dynamic child) {
    final width = props['width'];
    final height = props['height'];
    final buf = StringBuffer();
    buf.write(_indent(indent));
    buf.write('SizedBox(');
    if (width != null) buf.write('width: ${_emitLiteral(width)}, ');
    if (height != null) buf.write('height: ${_emitLiteral(height)}, ');
    if (child != null) {
      buf.write('child: ');
      buf.write('\n${emitWidget(child, indent: indent + 2)}');
      buf.write('\n${_indent(indent)}');
    }
    buf.write('),');
    return buf.toString();
  }

  String _emitCard(Map<String, dynamic> props, int indent, dynamic child) {
    final elevation = props['elevation'];
    final margin = props['margin'];
    final buf = StringBuffer();
    buf.write(_indent(indent));
    buf.write('Card(');
    if (elevation != null) buf.write('elevation: ${_emitLiteral(elevation)}, ');
    if (margin != null) buf.write('margin: ${_emitLiteral(margin)}, ');
    if (child != null) {
      buf.write('child: ');
      buf.write('\n${emitWidget(child, indent: indent + 2)}');
      buf.write('\n${_indent(indent)}');
    }
    buf.write('),');
    return buf.toString();
  }

  String _emitImage(Map<String, dynamic> props, int indent) {
    final source = props['source'] ?? '';
    final fit = props['fit'];
    final width = props['width'];
    final height = props['height'];
    final buf = StringBuffer();
    buf.write(_indent(indent));
    if ((props['network'] ?? false) == true) {
      buf.write('Image.network(');
    } else {
      buf.write('Image.asset(');
    }
    buf.write(_emitLiteral(source));
    if (fit != null) buf.write(', fit: ${_emitLiteral(fit)}');
    if (width != null) buf.write(', width: ${_emitLiteral(width)}');
    if (height != null) buf.write(', height: ${_emitLiteral(height)}');
    buf.write('),');
    return buf.toString();
  }

  String _emitSwitch(Map<String, dynamic> props, int indent) {
    final value = props['value'] ?? false;
    final onChanged = props['onChanged'] ?? '(v) {}';
    return _indent(indent) +
        'Switch(value: ${_emitLiteral(value)}, onChanged: ${_emitLiteral(onChanged)}),';
  }

  String _emitCheckbox(Map<String, dynamic> props, int indent) {
    final value = props['value'] ?? false;
    final onChanged = props['onChanged'] ?? '(v) {}';
    return _indent(indent) +
        'Checkbox(value: ${_emitLiteral(value)}, onChanged: ${_emitLiteral(onChanged)}),';
  }

  String _emitForm(Map<String, dynamic> props, int indent, dynamic child, List children) {
    final key = props['key'];
    final buf = StringBuffer();
    buf.write(_indent(indent));
    buf.write('Form(');
    if (key != null) buf.write('key: ${_emitLiteral(key)}, ');
    if (child != null) {
      buf.write('child: ');
      buf.write('\n${emitWidget(child, indent: indent + 2)}');
      buf.write('\n${_indent(indent)}');
    } else if (children.isNotEmpty) {
      buf.write('child: Column(');
      buf.write('\n${_indent(indent + 2)}children: [\n');
      for (final c in children) {
        buf.write(emitWidget(c, indent: indent + 4));
        buf.write('\n');
      }
      buf.write('${_indent(indent + 2)}],');
      buf.write('\n${_indent(indent)}');
      buf.write('),');
    }
    buf.write('),');
    return buf.toString();
  }

  String _emitGeneric(String type, Map<String, dynamic> props, int indent, dynamic child, List children) {
    final buf = StringBuffer();
    buf.write(_indent(indent));
    buf.write('$type(');
    if (props.isNotEmpty) {
      buf.write('\n');
      props.forEach((key, value) {
        buf.write('${_indent(indent + 2)}$key: ${_emitLiteral(value)},\n');
      });
    }
    if (child != null) {
      buf.write('${_indent(indent + 2)}child: ');
      buf.write('\n${emitWidget(child, indent: indent + 4)}');
      buf.write('\n');
    } else if (children.isNotEmpty) {
      buf.write('${_indent(indent + 2)}children: [\n');
      for (final c in children) {
        buf.write(emitWidget(c, indent: indent + 4));
        buf.write('\n');
      }
      buf.write('${_indent(indent + 2)}],\n');
    }
    buf.write('${_indent(indent)}),');
    return buf.toString();
  }

  String _emitLiteral(dynamic value) {
    if (value == null) return 'null';
    if (value is num || value is bool) return value.toString();
    if (value is String) {
      if (_looksLikeExpression(value)) return value;
      return json.encode(value);
    }
    if (value is List) {
      return '[${value.map(_emitLiteral).join(', ')}]';
    }
    if (value is Map) {
      final entries = value.entries.map((e) => '${_emitLiteral(e.key)}: ${_emitLiteral(e.value)}');
      return '{${entries.join(', ')}}';
    }
    return json.encode(value.toString());
  }

  bool _looksLikeExpression(String v) {
    return v.startsWith('Colors.') ||
        v.startsWith('Icons.') ||
        v.startsWith('EdgeInsets.') ||
        v.startsWith('Alignment.') ||
        v.startsWith('Border.') ||
        v.startsWith('TextStyle(') ||
        v.startsWith('MainAxisAlignment.') ||
        v.startsWith('CrossAxisAlignment.') ||
        v.startsWith('Axis.') ||
        v.startsWith('()') ||
        v.contains('=>');
  }

  String _indent(int n) => ' ' * n;
}

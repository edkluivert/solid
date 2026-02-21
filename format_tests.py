import re

with open('test/solid_test.dart', 'r') as f:
    text = f.read()

# Replace SolidViewModel<X> with Solid
text = re.sub(r'class (_[A-Za-z0-9_]+) extends SolidViewModel<([A-Za-z0-9_]+)> {',
               r'class \1 extends Solid {\n  \1() {\n    push<\2>(const \2());\n  }', text)

# For _NameVm which has super('world')
text = text.replace("class _NameVm extends Solid {\n  _NameVm() {\n    push<String>(const String());\n  }\n  _NameVm() : super('world');",
                    "class _NameVm extends Solid {\n  _NameVm() {\n    push<String>('world');\n  }")

# Replace emit(val) with push<X>(val) -- tricky because of X.
# We will just write a new test file completely to be clean.

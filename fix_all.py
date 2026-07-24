import os
import glob

base_dir = "lib/features"

# 1. Inject missing imports
files_to_fix = [
    "core_ui/presentation/widgets/top_toolbar.dart",
    "core_ui/presentation/widgets/bottom_status_bar.dart",
    "assets/presentation/screens/assets_view.dart",
    "dependencies/presentation/screens/dependencies_view.dart",
    "code_analyzer/presentation/screens/analyzer_view.dart",
    "imports/presentation/screens/imports_view.dart",
    "performance/presentation/screens/performance_view.dart",
    "release/presentation/screens/release_view.dart"
]

project_provider_import = "import 'package:flutter_dev_assistant/features/project/presentation/providers/project_provider.dart';\n"
analysis_provider_import = "import 'package:flutter_dev_assistant/features/project_analysis/presentation/providers/analysis_provider.dart';\n"
provider_import = "import 'package:provider/provider.dart';\n"

for rel_path in files_to_fix:
    path = f"{base_dir}/{rel_path}"
    if not os.path.exists(path):
        continue
    with open(path, 'r') as f:
        content = f.read()
    
    modified = False
    if "ProjectProvider" in content and "package:flutter_dev_assistant/features/project/presentation/providers/project_provider.dart" not in content:
        content = project_provider_import + content
        modified = True
    if "AnalysisProvider" in content and "package:flutter_dev_assistant/features/project_analysis/presentation/providers/analysis_provider.dart" not in content:
        content = analysis_provider_import + content
        modified = True
    if "context.watch" in content and "package:provider/provider.dart" not in content:
        content = provider_import + content
        modified = True
        
    if modified:
        with open(path, 'w') as f:
            f.write(content)

# 2. Fix main_shell.dart multi_split_view
main_shell_path = f"{base_dir}/core_ui/presentation/screens/main_shell.dart"
with open(main_shell_path, 'r') as f:
    content = f.read()

content = content.replace("weight:", "flex:")
content = content.replace("minimalSize:", "min:")
content = content.replace("children: activeWidgets,", "builder: (BuildContext context, Area area) => activeWidgets[area.index],")

with open(main_shell_path, 'w') as f:
    f.write(content)

print("Fixes applied.")

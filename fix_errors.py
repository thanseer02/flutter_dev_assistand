import os

base_dir = "lib/features"

# 1. Fix ProjectProvider
provider_path = f"{base_dir}/project/presentation/providers/project_provider.dart"
with open(provider_path, 'r') as f:
    content = f.read()

if "recentProjects" not in content:
    content = content.replace("class ProjectProvider extends ChangeNotifier {", 
                              "class ProjectProvider extends ChangeNotifier {\n  List<String> get recentProjects => [_prefs.getString('recent_project_path') ?? ''].where((s) => s.isNotEmpty).toList();\n  Future<void> openProject(String path) => scanProject(path);\n")
    with open(provider_path, 'w') as f:
        f.write(content)

# 2. Fix Dashboard imports
dashboard_path = f"{base_dir}/project/presentation/screens/dashboard_view.dart"
with open(dashboard_path, 'r') as f:
    content = f.read()

content = content.replace("../../../../project_analysis/", "../../../project_analysis/")
with open(dashboard_path, 'w') as f:
    f.write(content)

# 3. Fix missing imports in other files
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
    if "ProjectProvider" in content and "project_provider.dart" not in content:
        content = project_provider_import + content
        modified = True
    if "AnalysisProvider" in content and "analysis_provider.dart" not in content:
        content = analysis_provider_import + content
        modified = True
    if "context.watch" in content and "provider.dart" not in content:
        content = provider_import + content
        modified = True
        
    if modified:
        with open(path, 'w') as f:
            f.write(content)

print("Files patched.")

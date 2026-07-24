import glob
import os

files = glob.glob('lib/features/**/*.dart', recursive=True)

for path in files:
    with open(path, 'r') as f:
        lines = f.readlines()
    
    new_lines = []
    modified = False
    for line in lines:
        if "import '../../../../project" in line:
            # Check if it's project_timeline_chart.dart which has 4 levels depth
            if 'project_timeline_chart.dart' in path:
                # Actually, project_timeline_chart.dart is lib/features/project/presentation/widgets/charts/project_timeline_chart.dart
                # 1: charts->widgets, 2: widgets->presentation, 3: presentation->project, 4: project->features
                # So ../../../../ is features! It's CORRECT.
                new_lines.append(line)
            else:
                modified = True
                pass # skip this line
        else:
            new_lines.append(line)
            
    if modified:
        with open(path, 'w') as f:
            f.writelines(new_lines)

print("Fixed imports")

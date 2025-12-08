import os
import re

def fix_logger_type_mismatch_comprehensive(directory):
    files_fixed = 0
    
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.ps1') or file.endswith('.psm1'):
                filepath = os.path.join(root, file)
                try:
                    with open(filepath, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    original = content
                    
                    # Patterns to match strict Logger type usage
                    # 1. Property definition in class: [Logger]$_logger
                    # 2. Constructor/Method parameter: ([Logger]$logger)
                    # 3. Hidden property: hidden [Logger] $_logger
                    
                    # We replace with [object] to bypass type identity issues caused by double-loading
                    
                    new_content = content.replace('[Logger]$_logger', '[object]$_logger')
                    new_content = new_content.replace('[Logger] $_logger', '[object] $_logger')
                    new_content = new_content.replace('([Logger]$logger)', '([object]$logger)')
                    new_content = new_content.replace('([Logger] $logger)', '([object] $logger)')
                    
                    # Also handle the fully qualified name if it exists
                    new_content = new_content.replace('[SpeedTUI.Core.Logger]', '[object]')
                    
                    if new_content != original:
                        print(f"Relaxed [Logger] type constraint in: {filepath}")
                        with open(filepath, 'w', encoding='utf-8') as f:
                            f.write(new_content)
                        files_fixed += 1
                                
                except Exception as e:
                    print(f"Failed to process {filepath}: {e}")

    print(f"Total files fixed: {files_fixed}")

fix_logger_type_mismatch_comprehensive('working')

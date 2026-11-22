"""Convert CDO Training markdown chapters to typst and compile to PDF."""
import subprocess, os, glob, re, sys

BOOK_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'book'))
TYPST_DIR = os.path.dirname(os.path.abspath(__file__))
OUT_DIR = os.path.join(TYPST_DIR, 'pdf')
os.makedirs(OUT_DIR, exist_ok=True)
os.makedirs(os.path.join(TYPST_DIR, 'chapters'), exist_ok=True)

chapters = [
    ('introduction', 'Introduction to CDO'),
    ('installation', 'Installation and Setup'),
    ('basics', 'CDO Basics'),
    ('operators', 'CDO Operators'),
    ('netcdf', 'NetCDF Data Format'),
    ('grib', 'GRIB Data Format'),
    ('temporal', 'Temporal Analysis'),
    ('spatial', 'Spatial Analysis'),
    ('statistics', 'Statistics and Indices'),
    ('climate_indices', 'Climate Indices'),
    ('workflows', 'Workflows and Automation'),
    ('projects', 'Projects and Case Studies'),
    ('references', 'References'),
    ('../solutions/solution_01_intro', 'Solution 1: CDO Basics'),
    ('../solutions/solution_02_file_ops', 'Solution 2: File Operations'),
    ('../solutions/solution_03_temporal', 'Solution 3: Temporal Analysis'),
    ('../solutions/solution_04_spatial', 'Solution 4: Spatial Analysis'),
    ('../solutions/solution_05_statistics', 'Solution 5: Statistics and Climate Indices'),
]

def figure_directives_to_images(content):
    """Convert MyST {figure} fences into standard markdown images for pandoc."""
    lines = content.splitlines()
    out = []
    i = 0
    while i < len(lines):
        line = lines[i]
        if line.startswith('```{figure}'):
            path = line.split(None, 1)[1].strip() if len(line.split(None, 1)) > 1 else ''
            i += 1
            # Skip directive options such as :name:
            while i < len(lines) and lines[i].startswith(':'):
                i += 1
            while i < len(lines) and not lines[i].strip():
                i += 1
            caption = []
            while i < len(lines) and lines[i].strip() != '```':
                caption.append(lines[i].strip())
                i += 1
            if i < len(lines):
                i += 1  # closing fence
            if path:
                out.append(f'![{" ".join(caption)}]({path})')
                out.append('')
            continue
        out.append(line)
        i += 1
    return '\n'.join(out)


def fix_typst(content):
    """Fix pandoc-generated typst for compatibility with typst 0.15."""
    # horizontalrule -> line
    content = content.replace('#horizontalrule', '#line(length: 100%, stroke: 0.5pt)')
    # Generated chapters live in typst/chapters/, so asset paths from book/*.md
    # need one extra '../' to still resolve to the repository-root assets/.
    content = content.replace('image("../assets/', 'image("../../assets/')
    # Fix raw blocks - pandoc uses triple-backtick fences, ensure proper
    return content

# Create main.typ
main_lines = [
    '#import "template.typ": *',
    '',
    '#let book-title = "Climate Data Operators (CDO): Complete Training"',
    '#let book-subtitle = "A Comprehensive Guide to Climate Data Processing, Analysis, and Visualization"',
    '#let book-author = "Birhanu Asmerom, Department of Physics, Wollo University"',
    '#let book-date = "July 2026"',
    '',
    '#show: book-template.with(',
    '  title: book-title,',
    '  subtitle: book-subtitle,',
    '  author: book-author,',
    '  date: book-date,',
    ')',
    '',
    '= Preface',
    '',
    'This book provides a comprehensive training in Climate Data Operators (CDO),',
    'a command-line tool suite for efficient processing and analysis of climate and',
    'NWP model data. The material covers everything from basic installation to',
    'advanced workflows, with hands-on exercises using real climate datasets.',
    '',
    'The training is designed for climate scientists, researchers, and students',
    'who work with climate data in NetCDF, GRIB, and other formats. No prior',
    'experience with CDO is required, but basic familiarity with the command line',
    'is assumed.',
    '',
    '#pagebreak()',
    '',
]

for slug, title in chapters:
    md_file = os.path.join(BOOK_DIR, f'{slug}.md')
    out_slug = os.path.basename(slug)
    typ_file = os.path.join(TYPST_DIR, 'chapters', f'{out_slug}.typ.gen')

    if os.path.exists(md_file):
        with open(md_file, 'r', encoding='utf-8') as f:
            md_content = figure_directives_to_images(f.read())
        result = subprocess.run(
            ['pandoc', '-f', 'markdown+smart', '-t', 'typst', '-o', typ_file],
            input=md_content, capture_output=True, text=True, encoding='utf-8'
        )
        if result.returncode == 0:
            # Post-process with fixes
            with open(typ_file, 'r', encoding='utf-8') as f:
                content = f.read()
            content = fix_typst(content)
            with open(typ_file, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f'Converted: {slug}.md')
        else:
            print(f'Error: {slug}: {result.stderr[:100]}')
            with open(typ_file, 'w') as f:
                f.write(f'= {title}\n\nContent conversion failed.\n')
    else:
        print(f'Missing: {md_file}')
        with open(typ_file, 'w') as f:
            f.write(f'= {title}\n\nContent not available.\n')

    main_lines.append(f'#include "chapters/{out_slug}.typ.gen"')
    main_lines.append('')

# Write main.typ
main_path = os.path.join(TYPST_DIR, 'main.typ')
with open(main_path, 'w') as f:
    f.write('\n'.join(main_lines))
print(f'\nWritten: main.typ')

# Compile to PDF
pdf_path = os.path.join(OUT_DIR, 'cdo-training-complete.pdf')
print(f'\nCompiling typst -> PDF...')
sys.stdout.flush()
result = subprocess.run(
    ['typst', 'compile', '--root', os.path.join(TYPST_DIR, '..'), main_path, pdf_path],
    capture_output=True, text=True, timeout=120
)
if result.returncode == 0:
    size = os.path.getsize(pdf_path)
    print(f'PDF created: {pdf_path} ({size/1024/1024:.1f} MB)')
    if result.stdout:
        print(result.stdout[:500])
else:
    print(f'ERROR:')
    for line in result.stderr.split('\n'):
        if line.strip():
            print(f'  {line}')
    if result.stdout:
        print(result.stdout[:500])

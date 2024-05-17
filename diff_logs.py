# Copyright 2024 Antmicro
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import glob
import difflib
import os
from collections import defaultdict

# diff reports and generate a new one:

def diff_line(a, b):
    a_segments = a.split("|")[1:-1]
    b_segments = b.split("|")[1:-1]
    differences = []
    if a_segments[0] == b_segments[0]:
        for sa,sb in zip(a_segments[1:], b_segments[1:]):
            differences.append(round(float(sa) - float(sb), 3))
    else:
        raise Exception("The step headers don't match, aborting!")
    reconstructed_line = '|' + "| ".join(
        a_segments[0:1] + [str(i) + " " for i in differences] + ['\n']
    )
    return reconstructed_line

def generate_differential_timing_report(file_a, file_b, file_out):
    differential_lines = [
        "# Differential report of OpenROAD revisions\n\n",
        "Base times are taken from Revision A (see `REVISIONS.toml`)\n",
        "and compared against Revision B (`result = time_a - time_b`).\n\n",
        "Given this arrangement, negative times represent an improvement\n",
        "in Revision B, while positive times represent a regression.\n\n"
    ]
    with open(file_a, 'r') as fa:
        lines_a = fa.readlines()

    with open(file_b, 'r') as fb:
        lines_b = fb.readlines()
            
    for la, lb in zip(lines_a, lines_b):
        # append headings
        if la.startswith('##') and lb.startswith("##"):
            differential_lines.append(la)
        # ... empty lines
        elif la.startswith('\n') and lb.startswith('\n'):
            differential_lines.append(la)
        # .. and table headers
        elif la.startswith('| step') and lb.startswith('| step'):
            differential_lines.append(la)
        elif la.startswith('| ---') and lb.startswith('| ---'):
            differential_lines.append(la)
        else: 
            differential_lines.append(diff_line(la, lb))
    with open(file_out, 'w') as f:
        for line in differential_lines:
            f.write(line)

# diff logs:

def read_file(file_path):
    with open(file_path, 'r') as file:
        return file.readlines()

def get_project_run_step(file_path):
    base_name = os.path.basename(file_path)
    project_name = file_path.split('/')[2].split('_')[1]
    revision = file_path.split('/')[1]
    run_step = base_name.split('_')
    run_no = int(run_step[1])
    step_no = "_".join(run_step[2:-1]).split('.')[0]
    cores = int(run_step[-1].split('.')[0])
    return project_name, run_no, step_no, cores, revision

def realign_match(match: str):
    return [line + '\n' for line in match.split('\n')]

def _line_filter(line: str):
    if line.startswith("Elapsed"):
        return False
    return True

def manual_variable_data_filter(lines: list):
    return [line for line in lines if _line_filter(line)]

def eliminate_noise(log_files):
    logs_content = [read_file(f) for f in log_files]
    
    common = manual_variable_data_filter(logs_content[0])
    for log in logs_content[1:]:
        log = "".join(manual_variable_data_filter(log))
        common = "".join(common)
        common = list(difflib.SequenceMatcher(None, common, log).get_matching_blocks())
        common = "".join(["".join(log[common[i].b : common[i].b + common[i].size]) for i in range(len(common))])
        common = realign_match(common)
    return common

def generate_differential_log_report(log_directory, file_out):
    # Gather all log files
    reportfile = open(file_out, 'a')
    log_files = glob.glob(f'{log_directory}/**/*.log', recursive=True)
    
    # Organize logs by project, step and run
    logs = defaultdict(lambda: defaultdict(lambda: defaultdict(lambda: defaultdict(list))))
    for log_file in log_files:
        project, _, step, cores, revision = get_project_run_step(log_file)
        logs[project][step][cores][revision].append(log_file)
    
    # Eliminate noise within each project and step
    for project, steps in logs.items():
        for step, cores  in steps.items():
            for core, revisions in cores.items():
                print("## Diff of logs from:", project+",", "step:", step, "at core count:", core,"\n", file=reportfile)
                print("```", file=reportfile)
                noiseless_log_a = eliminate_noise(revisions['a'])
                noiseless_log_b = eliminate_noise(revisions['b'])
                diff = difflib.unified_diff(noiseless_log_a, noiseless_log_b, fromfile="rev_a", tofile="rev_b")
                lines = 0
                for line in diff:
                    print(line, end='', file=reportfile)
                    lines += 1
                if lines == 0:
                    print("none", file=reportfile)
                print("```", file=reportfile)


# run:

def run():
    generate_differential_timing_report('diff/a/report.md', 'diff/b/report.md', 'diff_report.md')
    generate_differential_log_report('diff', "diff_report.md")

if __name__ == "__main__":
    run()

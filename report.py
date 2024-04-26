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

"""
Generates a markdown report from downloaded run logs

USAGE: python3 report.py
"""

import os
from statistics import mean, median, stdev
from common import steps
from glob import glob

table_data = {}

def process_design_logs(design):
    assert os.path.exists(f"./output_{design}")
    files = glob(f"./output_{design}/*")
    runs_no = max([int(i.split('/')[-1].split('_')[1]) for i in files])
    core_counts = sorted(list(set([int(i.split('_')[-1].split('.')[0]) for i in files])))
    for number in range(runs_no):
        for step in steps:
            for cores in core_counts:
                if not os.path.exists(f"output_{design}/run_{number}_{step}_{cores}.log"):
                    if cores not in table_data:
                        table_data[cores] = {}
                    if design not in table_data[cores]:
                        table_data[cores][design] = {}
                    if step not in table_data[cores][design]:
                        table_data[cores][design][step] = {}

                with open(f"output_{design}/run_{number}_{step}_{cores}.log", "r") as f:
                    for line in f:
                        if line.startswith("Elapsed"):
                            line = line.split("[h:]min:sec.")[0]
                            line = line.split("Elapsed time: ")[1]
                            colons = line.count(':')
                            # since there is an optional 'hours' field, it needs to be parsed properly
                            seconds = 0
                            if colons == 1:
                                timesegments = line.split(':')
                                seconds = int(timesegments[0])*60 + float(timesegments[1])
                            elif colons == 2:
                                timesegments = line.split(':')
                                seconds = int(timesegments * 3600) + int(timesegments[1])*60 + float(timesegments[2])
                            else:
                                raise Exception("Invalid time chunk extracted")
                            if cores not in table_data:
                                table_data[cores] = {}
                            if design not in table_data[cores]:
                                table_data[cores][design] = {}
                            if step not in table_data[cores][design]:
                                table_data[cores][design][step] = {}

                            table_data[cores][design][step][str(number)] = seconds
def render_table(table):
    for core in table.keys():
        for design in table[core].keys():
            data = [
                {
                    "step": k,
                    "Mean (s)": round(mean([run for _, run in v.items()]),3),
                    "SD (s)": round(stdev([run for _, run in v.items()]),3),
                    "Median (s)": round(median([run for _, run in v.items()]),3),
                    "Min (s)": round(min([run for _, run in v.items()]),3)
                } for k,v in table[core][design].items()
            ]
            print("##", design, "at", str(core),"cores run statistics:", end="\n\n")
            for key in data[0].keys():
                print("|", key, end=" ")
            print("|")
            for key in data[0].keys():
                print("| ---", end=" ")
            print("|")
            for row in data:
                for _, value in row.items():
                    print("|", value, end=" ")
                print("|")

if __name__ == "__main__":
    process_design_logs("ibex")
    process_design_logs("tinyRocket")
    process_design_logs("black_parrot")

    render_table(table_data)

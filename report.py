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
from statistics import mean, median
from common import steps, runs_no

table_data = {}

def process_design_logs(design):
    assert os.path.exists(f"./output_{design}")
    for number in range(runs_no):
        for step in steps:
            with open(f"output_{design}/run_{number}_{step}.log", "r") as f:
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
                        if design not in table_data:
                            table_data[design] = {}
                        if step not in table_data[design]:
                            table_data[design][step] = {}

                        table_data[design][step][str(number)] = seconds
def render_table(table):
    for design in table.keys():
        data = [
            {
                "step": k,
                "Mean (s)": mean([run for _, run in v.items()]),
                "SD (s)": stdev([run for _, run in v.items()]),
                "Median (s)": median([run for _, run in v.items()]),
                "Min (s)": min([run for _, run in v.items()])
            } for k,v in table[design].items()
        ]
        print("##", design, "run statistics:", end="\n\n")
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

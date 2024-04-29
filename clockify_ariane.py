#!/usr/bin/env python3

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

import sys
from copy import copy

# This script adds 50 clocks to the ariane.sdc constraint file
clk_line = ""
lines = []
with open(sys.argv[1], "r") as f:
    for line in f.readlines():
        if line.startswith("create_clock"):
            clk_line = copy(line)
        else: lines.append(line)
for i in range(50):
    lines.append(clk_line.replace("core_clock", f"core_clock_{i}").replace("4.0", f"4.{i}"))

with open(sys.argv[1], "w") as f:
    f.writelines(lines)

sdc_line = ""
config_lines = []
with open(sys.argv[2], "r") as f:
    for line in f.readlines():
        if line.startswith("export SDC_FILE"):
            sdc_line = copy(line)
            config_lines.append(sdc_line.replace("ariane133", "ariane133_50clk"))
        else: config_lines.append(line)

with open(sys.argv[2], "w") as f:
    f.writelines(config_lines)

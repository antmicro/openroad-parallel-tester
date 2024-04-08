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

import os
import sys
import time
import subprocess
from tqdm import tqdm
from common import steps, runs_no

def measure_steps(design: str):
    for number in tqdm(range(runs_no)):
        for step in tqdm(steps, leave=False):
            run_cmd = f"make -C OpenROAD-flow-scripts/flow/ DESIGN_CONFIG=designs/nangate45/{design}/config.mk {step}  OR_ARGS='-threads 4'"
            output_dir = f"output_{design}"
            if not os.path.exists(output_dir):
                os.mkdir(output_dir)
            with open(f"output_{design}/run_{number}_{step}.log", "w") as f:
                proc = subprocess.run(run_cmd, shell=True, stdout=f, stderr=f)
                if proc.returncode != 0:
                    raise Exception("Subprocess failed")


if __name__ == "__main__":
    measure_steps(sys.argv[1])

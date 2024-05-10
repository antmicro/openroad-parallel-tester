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
import subprocess
import sched
from threading import Thread
import time
import os

# timeout time to kill a process that
# hasn't logged anything for set amout of seconds
TIMEOUT_TIME = 5400
BENCH_PROC = None

def check(sched, filename, last, iter_left):
    global BENCH_PROC
    with open(filename, 'rb') as f:
        f.seek(0, os.SEEK_END)
        last_size = f.tell()
    if last_size == last:
        if iter_left != 0:
            iter_left -= 1
        else:
            print("PROCESS IS NOT RESPONDING, KILLING")
            BENCH_PROC.kill() # type: ignore
            list(map(sched.cancel, sched.queue))
            with open(filename, 'r') as f:
                print(f.read())
            return
    else:
        last = last_size
        iter_left = TIMEOUT_TIME
    sched.enter(1, 1, check, (sched, filename, last, iter_left))

def measure_steps(design: str, threads: int, run_number=-1):
    break_flag = False
    global BENCH_PROC
    for number in tqdm(range(runs_no)):
        for step in tqdm(steps, leave=False):
            try_count = 0
            while try_count < 9:
                try_count += 1
                print(f"Try of step {step} number {try_count}")

                run_cmd = f"make -C OpenROAD-flow-scripts/flow/ DESIGN_CONFIG=designs/nangate45/{design}/config.mk {step}  OR_ARGS='-threads {threads}'"
                output_dir = f"output_{design}"
                if not os.path.exists(output_dir):
                    os.mkdir(output_dir)

                if run_number != -1:
                    number = run_number
                    break_flag = True

                filename = f"output_{design}/run_{number}_{step}_{threads}.log"

                with open(filename, "w") as f:
                    s = sched.scheduler(time.time, time.sleep)
                    mem_ev = s.enter(0, 1, check, (s, filename, "", TIMEOUT_TIME))
                    thread = Thread(target = s.run)
                    thread.start()

                    BENCH_PROC = subprocess.Popen(run_cmd, shell=True, stdout=f, stderr=f)
                    BENCH_PROC.wait()

                    list(map(s.cancel, s.queue))
                    thread.join()

                if BENCH_PROC.returncode != 0:
                    BENCH_PROC = None
                    print("ERROR: Subprocess failed\nlogs:")
                    with open(f"output_{design}/run_{number}_{step}_{threads}.log", "r") as f:
                        print(f.read()) 
                    # clear the data file
                    open(f"output_{design}/run_{number}_{step}_{threads}.log", "w").close()
                else:
                    BENCH_PROC = None
                    break

        if break_flag:
            break


if __name__ == "__main__":
    if len(sys.argv) == 4:
        measure_steps(sys.argv[1], int(sys.argv[2]), int(sys.argv[3]))
    else:
        measure_steps(sys.argv[1], int(sys.argv[2]))

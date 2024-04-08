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

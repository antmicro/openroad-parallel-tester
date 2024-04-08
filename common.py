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

runs_no = 5
steps = [
    "do-2_1_floorplan",
    "do-2_2_floorplan_io",
    "do-2_3_floorplan_tdms",
    "do-2_4_floorplan_macro",
    "do-2_5_floorplan_tapcell",
    "do-2_6_floorplan_pdn",
    "do-3_1_place_gp_skip_io",
    "do-3_2_place_iop",
    "do-3_3_place_gp",
    "do-3_4_place_resized",
    "do-3_5_place_dp",
    "do-4_1_cts",
    "do-5_1_grt"
]


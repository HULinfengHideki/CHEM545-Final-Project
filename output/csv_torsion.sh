#!/usr/bin/env bash

# Output CSV file
out="torsion_gas.csv"

# Write header
echo "angle_deg,E_S0_au,S1_vert_eV,E_S1_au,f_S1,S2_vert_eV,E_S2_au,f_S2" > "$out"

# Angle list (0 to 180 in steps of 15)
for angle in 0 15 30 45 60 75 90 105 120 135 150 165 180; do
    file="${angle}_gas.qcout"

    if [[ ! -f "$file" ]]; then
        echo "Warning: $file not found, skipped." >&2
        continue
    fi

    # 1) Ground-state energy (S0)
    # Adjust this grep pattern if your qcout uses a different phrase.
    E_S0=$(grep -m1 "Total energy in the final basis set" "$file" | awk '{print $(NF-1)}')

    # 2) Extract S1 and S2 data using awk
    read S1_vert E_S1 f1 S2_vert E_S2 f2 < <(
        awk '
        /Excited state[[:space:]]+1:/ {
            # line like: Excited state   1: excitation energy (eV) =   2.9985
            for (i = 1; i <= NF; i++) {
                if ($i == "=") { e1 = $(i+1); break }
            }
            flag1 = 1
        }
        flag1 && /Total energy for state[[:space:]]+1:/ {
            # line like: Total energy for state   1:   -572.47068747 au
            e1tot = $(NF-1)
        }
        flag1 && /Strength/ {
            # line like: Strength   :     0.0635948257
            f1 = $NF
            flag1 = 0
        }

        /Excited state[[:space:]]+2:/ {
            for (i = 1; i <= NF; i++) {
                if ($i == "=") { e2 = $(i+1); break }
            }
            flag2 = 1
        }
        flag2 && /Total energy for state[[:space:]]+2:/ {
            e2tot = $(NF-1)
        }
        flag2 && /Strength/ {
            f2 = $NF
            flag2 = 0
        }

        END {
            # Output: S1_vert  E_S1  f1  S2_vert  E_S2  f2
            printf "%s %s %s %s %s %s", e1, e1tot, f1, e2, e2tot, f2
        }' "$file"
    )

    # 3) Append to CSV
    echo "$angle,$E_S0,$S1_vert,$E_S1,$f1,$S2_vert,$E_S2,$f2" >> "$out"
done

echo "Done. Results saved to $out"


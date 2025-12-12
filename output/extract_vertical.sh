#!/usr/bin/env bash

out="vertical_summary.csv"
echo "name,S1_vert_eV,E_S1_au,f_S1,S2_vert_eV,E_S2_au,f_S2" > "$out"

for file in *vert*.qcout; do
    if [[ ! -f "$file" ]]; then
        continue
    fi

    # Extract S1 and S2 via awk
    read S1_vert E_S1 f1 S2_vert E_S2 f2 < <(
        awk '
        /Excited state[[:space:]]+1:/ {
            for (i=1;i<=NF;i++) if ($i=="=") { e1=$(i+1); break }
            flag1=1
        }
        flag1 && /Total energy for state[[:space:]]+1:/ { e1tot=$(NF-1) }
        flag1 && /Strength/ { f1=$NF; flag1=0 }

        /Excited state[[:space:]]+2:/ {
            for (i=1;i<=NF;i++) if ($i=="=") { e2=$(i+1); break }
            flag2=1
        }
        flag2 && /Total energy for state[[:space:]]+2:/ { e2tot=$(NF-1) }
        flag2 && /Strength/ { f2=$NF; flag2=0 }

        END {
            printf "%s %s %s %s %s %s", e1, e1tot, f1, e2, e2tot, f2
        }' "$file"
    )

    echo "$file,$S1_vert,$E_S1,$f1,$S2_vert,$E_S2,$f2" >> "$out"
done

echo "Done. Output written to $out"


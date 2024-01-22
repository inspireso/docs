#!/usr/bin/env bash
# Usage: nvidia-oc delay|log|stop|reset|nocolor|quiet
# internal: delayed


OC_LOG=/var/log/nvidia-oc.log
OC_TIMEOUT=120
NVS_TIMEOUT=10
NVML_TIMEOUT=10
MAX_DELAY=300
MIN_DELAY=30
# apply without delay
NO_DELAY=10
PILLMEM=-1000
MIN_FIXCLOCK=500 # the above value is treated as fixed
export DISPLAY=":0"


[[ -f $RIG_CONF ]] && source $RIG_CONF
set -o pipefail

n=`gpu-detect NVIDIA`
if [[ $n -eq 0 ]]; then
        #echo "No NVIDIA cards detected"
        exit 0
fi

[[ "$1" != "nocolor" ]] && source colors

if [[ "$1" == "log" ]]; then
        [[ ! -f $OC_LOG ]] && echo "${YELLOW}$OC_LOG does not exist${NOCOLOR}" && exit 1
        cat $OC_LOG 2>/dev/null && echo -e "\n${GRAY}=== $OC_LOG === $( stat -c %y $OC_LOG )${NOCOLOR}"
        exit
fi

# do not run OC simultaneously
if [[ "$2" != "internal" ]]; then
        if [[ "$1" == "delay" ]]; then
                [[ -f $NVIDIA_OC_CONF ]] && source $NVIDIA_OC_CONF
                # exit if no delay is set. OC is already applied
                [[ $RUNNING_DELAY -le 0 ]] &&
                        echo "${YELLOW}No delay is set, exiting${NOCOLOR}" &&
                        exit 0
        fi
        readarray -t pids < <( pgrep -f "timeout .*$OC_LOG" )
        for pid in "${pids[@]}"; do
                echo -e "${BYELLOW}Killing running nvidia-oc ($pid)${NOCOLOR}\n"
                # timeout process PID is equal to the PGID, so using it to kill process group
                kill -- -$pid
        done
fi

# just exit here
[[ "$1" == "stop" ]] && exit 0


[[ -f /run/hive/NV_OFF ]] &&
        echo "${YELLOW}NVIDIA driver is disabled, exiting${NOCOLOR}" &&
        exit 0

[[ $MAINTENANCE == 2 ]] &&
        echo "${YELLOW}Maintenance mode enabled, exiting${NOCOLOR}" &&
        exit 1


# start main OC with timeout and logging
if [[ "$2" != "internal" ]]; then
        trap "echo -n $NOCOLOR" EXIT
        timeout --foreground -s9 $OC_TIMEOUT bash -c "set -o pipefail; nvidia-oc \"$1\" internal 2>&1 | tee $OC_LOG"
        exitcode=$?
        if [[ $exitcode -ne 0 && $exitcode -ne 143 ]]; then
                echo "${RED}ERROR: NVIDIA OC failed${NOCOLOR}"
                [[ "$1" != "quiet" ]] && cat $OC_LOG | message error "NVIDIA OC failed" payload > /dev/null
        fi
        exit $exitcode
fi


print_array() {
        local desc=$1
        local arr=($2)
        local align=10
        local pad=5
        printf "%-${align}s :" "$desc"
        for item in "${arr[@]}"
        do
                printf "%${pad}s" "$item"
        done
        printf "\n"
}


apply_settings() {
        local args="$1"
        local exitcode
        local result
        [[ -z "$args" ]] && return 0
        echo -n "${RED}" # set color to red
        result=`timeout --foreground -s9 $NVS_TIMEOUT nvidia-settings $args 2>&1 | grep -v "^$"`
        exitcode=$?
        if [[ $exitcode -eq 0 ]]; then
                echo "${NOCOLOR}$result"
        else
                [[ ! -z "$result" ]] && echo "$result"
                [[ $exitcode -ge 124 ]] && echo "nvidia-settings failed by timeout (exitcode=$exitcode)${NOCOLOR}" || echo "(exitcode=$exitcode)${NOCOLOR}"
        fi
        return $exitcode
}

apply_nvml() {
        local args="$1"
        local exitcode
        local result
        [[ -z "$args" ]] && return 0
        echo -n "${RED}" # set color to red
        result=`timeout --foreground -s9 $NVML_TIMEOUT nvtool -q --nodev $args`
        exitcode=$?
        if [[ $exitcode -eq 0 ]]; then
                echo "${NOCOLOR}$result"
        else
                [[ ! -z "$result" ]] && echo "$result"
                [[ $exitcode -ge 124 ]] && echo "nvtool failed by timeout (exitcode=$exitcode)${NOCOLOR}" || echo "(exitcode=$exitcode)${NOCOLOR}"
        fi
        return $exitcode
}


date
echo -e "\nDetected $n NVIDIA cards\n"

hivex status >/dev/null || echo -e "${RED}ERROR: X Server is not running! Some settings will not be applied!${NOCOLOR}\n"


if [[ "$1" == "reset" ]]; then
        echo -e "${YELLOW}Resetting OC to defaults${NOCOLOR}\n"
else
        [[ ! -f $NVIDIA_OC_CONF ]] &&
                echo "${YELLOW}$NVIDIA_OC_CONF does not exist, exiting${NOCOLOR}" &&
                exit 0
        source $NVIDIA_OC_CONF
fi

if [[ ! -f $GPU_DETECT_JSON ]]; then
        gpu_detect_json=`gpu-detect listjson`
else
        gpu_detect_json=$(< $GPU_DETECT_JSON)
fi

readarray -t NAME   < <( echo "$gpu_detect_json" | jq -r '. | to_entries[] | select(.value.brand == "nvidia") | .value.name' )
readarray -t RAM    < <( echo "$gpu_detect_json" | jq -r '. | to_entries[] | select(.value.brand == "nvidia") | .value.mem' )
readarray -t BUSID  < <( echo "$gpu_detect_json" | jq -r '. | to_entries[] | select(.value.brand == "nvidia") | .value.busid' )
readarray -t PLMAX  < <( echo "$gpu_detect_json" | jq -r '. | to_entries[] | select(.value.brand == "nvidia") | .value.plim_max' )
readarray -t PLMIN  < <( echo "$gpu_detect_json" | jq -r '. | to_entries[] | select(.value.brand == "nvidia") | .value.plim_min' )
readarray -t PLDEF  < <( echo "$gpu_detect_json" | jq -r '. | to_entries[] | select(.value.brand == "nvidia") | .value.plim_def' )
readarray -t FANCNT < <( echo "$gpu_detect_json" | jq -r '. | to_entries[] | select(.value.brand == "nvidia") | .value.fan_cnt' )

n=${#BUSID[@]}
if [[ $n -eq 0 ]]; then
        echo -e "${RED}No cards available for OC!\n${NOCOLOR}Please check BIOS settings, risers, connectors and PSU.\nTry to update Nvidia drivers."
        exit 1
fi


[[ $OHGODAPILL_ENABLED -eq 1 && $OHGODAPILL_START_TIMEOUT -lt 0 ]] && PILLFIX=1 || PILLFIX=0

# delay is applied on every miner start
MSG=
NEED_DELAY=0
DELAY=$RUNNING_DELAY
[[ $DELAY -lt $NO_DELAY ]] && DELAY=0
if [[ $DELAY -gt 0 && "$1" != "delay" && "$1" != "delayed" ]]; then
        MSG=$'\n'"  ${YELLOW}Use ${BYELLOW}nvidia-oc delay${YELLOW} to apply OC with delay (${MAX_DELAY} secs)${NOCOLOR}"
        DELAY=0
fi
if [[ "$1" == "delayed" && $DELAY -gt 0 ]]; then
        [[ $DELAY -lt $MIN_DELAY ]] && DELAY=$MIN_DELAY
        [[ $MAX_DELAY -gt 0 && $DELAY -gt $MAX_DELAY ]] &&
                echo -e "${YELLOW}Limiting delay to ${MAX_DELAY} secs${NOCOLOR}" &&
                DELAY=$MAX_DELAY
        echo -e "${CYAN}Waiting $DELAY secs before applying...${NOCOLOR}\n"
        sleep $DELAY
        DELAY=0
        [[ $PILLFIX -eq 1 ]] && PILLFIX=-1 # Pill fix is already applied
else
        pgrep --full nvidia-persistenced > /dev/null || nvidia-persistenced --persistence-mode
        # kill Pill if running
        pkill -f '/hive/opt/ohgodapill/run.sh'
        pkill -f '/hive/opt/ohgodapill/OhGodAnETHlargementPill-r2'
fi


# MAP OC to MB BUS ID
[[ -f "$BUSID_FILE" ]] && source $BUSID_FILE
# prefer NVIDIA especially for mixed rigs
[[ ! -z "$BUSID_NVIDIA" ]] && BUSID_MB="$BUSID_NVIDIA"
if [[ ! -z "$BUSID_MB" ]]; then
        # add one more item to the end for not defined busid GPU
        BUSID_MB=($BUSID_MB "@")
        declare -A GPU_MAPPING
        for((idx=0; idx < ${#BUSID_MB[@]}; idx++))
        do
                GPU_MAPPING["${BUSID_MB[$idx]}"]=$idx     #"
        done
        n=${#BUSID_MB[@]}
fi

PARAMS=(CLOCK MEM PLIMIT FAN)

# pad arrays
for param in "${PARAMS[@]}"; do
        [[ -z ${!param} ]] && continue
        arr=(${!param})
        for ((i=${#arr[@]}; i < n; i++)); do
                read "$param[$i]" < <( echo "${arr[-1]}" ) # use last element of initial array
        done
done

# Remap OC according to bus id
if [[ ! -z $BUSID_MB ]]; then
        # map params to temp array
        for param in "${PARAMS[@]}"; do
                arr="${param}[*]"
                declare -a "_$param"="( ${!arr} )"
                unset "${param}"
        done
        for ((i=0; i < ${#BUSID[@]}; i++)); do
                busid=${BUSID[$i]/:00\.0}
                [[ ! -z $busid ]] && idx=${GPU_MAPPING[$busid]} || idx=
                [[ -z $idx ]] && idx=${GPU_MAPPING["@"]}
                #[[ $i -ne $idx ]] && echo "Mapping GPU $i settings to index $idx"
                # remap params
                for param in "${PARAMS[@]}"; do
                        val="_$param[$idx]"
                        read "$param[$i]" < <( echo "${!val}" )
                done
        done
        print_array "MB BUS ID" "${BUSID_MB[*]}"
else
        for param in "${PARAMS[@]}"; do
                arr="${param}[*]"
                declare -a "$param"="( ${!arr} )"
        done
fi

print_array "GPU BUS ID" "${BUSID[*]/:00\.0}"
for param in "${PARAMS[@]}"; do
        arr="${param}[*]"
        print_array "$param" "${!arr}"
done

[[ "${FANCNT[*]}" =~ [2-9] ]] &&
        print_array "FANCNT" "${FANCNT[*]//null/1}"


AUTOFAN_ENABLED=$( [[ `pgrep -cf "/autofan run"` -gt 0 && -f $AUTOFAN_CONF ]] && source $AUTOFAN_CONF && echo "$ENABLED" )

nvparams=
nvquery=`timeout --foreground -s9 $NVS_TIMEOUT nvidia-settings -q GPUMemoryTransferRateOffset -q GPUGraphicsClockOffset -q GPUTargetFanSpeed \
                 -q GPULogoBrightness -q GPUPowerMizerMode -q GPUPerfModes | grep -vE "values|target" | tr '\n' ' ' 2>&1`
nvcode=$?

if [[ $nvcode -eq 0 ]]; then
        nvparams="${nvquery//Attribute/$'\n'}"
elif [[ $nvcode -ge 124 ]]; then
        echo "${RED}NVS query error: nvidia-settings failed by timeout (exitcode=$nvcode)${NOCOLOR}"
else
        echo "${RED}NVS query error: $perfquery${NOCOLOR}"
fi


fan_idx=0
exitcode=0

for (( i=0; i < ${#BUSID[@]}; ++i )); do
        args=""

        echo ""
        echo "${YELLOW}===${NOCOLOR} GPU ${CYAN}$i${NOCOLOR}, ${BUSID[$i]} ${GREEN}${NAME[$i]} ${RAM[$i]}${NOCOLOR}, PL: ${PLMIN[$i]}, ${PLDEF[$i]}, ${PLMAX[$i]} ${YELLOW}=== `date +"%T"`${NOCOLOR}"

        pldef="${PLDEF[$i]%%[!0-9]*}"
        [[ -z "${PLIMIT[$i]}" ]] && PLIMIT[$i]=0

        if [[ ${CLOCK[$i]} -lt $MIN_FIXCLOCK ]]; then
                apply_nvml "-i $i --setclocks 0 --setpl ${PLIMIT[$i]}" || exitcode=$?
        else
                apply_nvml "-i $i --setpl ${PLIMIT[$i]}" || exitcode=$?
                apply_nvml "-i $i --setclocks ${CLOCK[$i]}" || exitcode=$?
                CLOCK[$i]=${DEF_FIXCLOCK:-0} # reset
        fi

        x=`echo "$nvparams" | grep -oP "'GPUPerfModes'.*\[gpu\:$i\].* perf=\K[0-9]+"`
        if [[ -z "$x" ]]; then
                x=3 # default
                if   [[ ${NAME[$i]} =~ "RTX" ]]; then x=4
                elif [[ ${NAME[$i]} =~ "P106-090" || ${NAME[$i]} =~ "P104-100" || ${NAME[$i]} =~ "P102-100" ]]; then x=1
                elif [[ ${NAME[$i]} =~ "1660 Ti"  || ${NAME[$i]} =~ "1660 SUPER" || ${NAME[$i]} =~ "1650 SUPER" ]]; then x=4
                elif [[ ${NAME[$i]} =~ "P106-100" || ${NAME[$i]} =~ "1050" || ${NAME[$i]} =~ "1650" || ${NAME[$i]} =~ "1660" ]]; then x=2
                fi
                echo "  ${GRAY}Max Perf mode: $x${NOCOLOR}"
        else
                echo "  ${GRAY}Max Perf mode: $x (auto)${NOCOLOR}"
        fi


        [[ `echo "$nvparams" | grep -oP "'GPUPowerMizerMode'.*\[gpu\:$i\]\): \K[0-9]+"` != "${POWERMIZER:-1}" ]] &&
                args+=" -a [gpu:$i]/GPUPowerMizerMode=${POWERMIZER:-1}"

        fans_count="${FANCNT[$i]}"
        [[ -z $fans_count || $fans_count == "null" ]] && fans_count=1

        [[ -z "${FAN[$i]}" ]] && FAN[$i]=0
        if [[ `echo "$nvparams" | grep -oP "'GPUTargetFanSpeed'.*\[gpu\:$i\]\): \K[0-9]+"` == "${FAN[$i]}" ]]; then
                echo "  ${GRAY}Attribute 'GPUTargetFanSpeed' was already set to ${FAN[$i]}${NOCOLOR}"
        else
                if [[ ${FAN[$i]} == 0 ]]; then
                        [[ "$AUTOFAN_ENABLED" != 1 ]] &&
                                args+=" -a [gpu:$i]/GPUFanControlState=0"
                else
                        args+=" -a [gpu:$i]/GPUFanControlState=1"
                        for (( z = fan_idx; z < fan_idx + fans_count; z++ )); do
                                args+=" -a [fan:$z]/GPUTargetFanSpeed=${FAN[$i]}"
                        done
                fi
        fi
        fan_idx=$(( fan_idx + fans_count ))


        [[ -z "${CLOCK[$i]}" ]] && CLOCK[$i]=0
        # if delay is set reset clocks for the first time (except 1080* in Pill Fix mode)
        [[ ${CLOCK[$i]} -gt 0 && $DELAY -gt 0 && ($PILLFIX -eq 0 || ! "${NAME[$i]}" =~ 1080) ]] && CLOCK[$i]=0 && NEED_DELAY=1
        if [[ `echo "$nvparams" | grep -oP "'GPUGraphicsClockOffset'.*\[gpu\:$i\]\): \K-?[0-9]+"` == "${CLOCK[$i]}" ]]; then
                echo "  ${GRAY}Attribute 'GPUGraphicsClockOffset' was already set to ${CLOCK[$i]}${NOCOLOR}"
        else
                args+=" -a [gpu:$i]/GPUGraphicsClockOffset[$x]=${CLOCK[$i]}"
        fi


        [[ -z "${MEM[$i]}" ]] && MEM[$i]=0
        # if delay is set reset clocks for the first time (except 1080* in Pill Fix mode)
        [[ $PILLFIX -eq 1 && "${NAME[$i]}" =~ 1080 && ${MEM[$i]} -gt $PILLMEM ]] && MEMCLOCK=0 || MEMCLOCK="${MEM[$i]}"
        [[ $MEMCLOCK -gt 0 && $DELAY -gt 0 ]] && MEMCLOCK=0 && NEED_DELAY=1
        if [[ `echo "$nvparams" | grep -oP "'GPUMemoryTransferRateOffset'.*\[gpu\:$i\]\): \K-?[0-9]+"` == "$MEMCLOCK" ]]; then
                echo "  ${GRAY}Attribute 'GPUMemoryTransferRateOffset' was already set to $MEMCLOCK${NOCOLOR}"
        else
                args+=" -a [gpu:$i]/GPUMemoryTransferRateOffset[$x]=$MEMCLOCK"
        fi


        brightness=`echo "$nvparams" | grep -oP "'GPULogoBrightness'.*\[gpu\:$i\]\): \K[0-9]+"`
        [[ ! -z "$brightness" && ! -z "$LOGO_BRIGHTNESS" && "$brightness" != "$LOGO_BRIGHTNESS" ]] &&
                args+=" -a [gpu:$i]/GPULogoBrightness=$LOGO_BRIGHTNESS"

        apply_settings "$args" || exitcode=$?

done

# start Pill if needed
if [[ "$OHGODAPILL_ENABLED" -eq 1 && $PILLFIX -ne -1 && ($NEED_DELAY -eq 0 || $PILLFIX -eq 1) ]]; then
        echo
        echo "${YELLOW}===${NOCOLOR} Starting OhGodAnETHlargementPill ${YELLOW}=== `date +"%T"`${NOCOLOR}"
        sleep 1

        if [[ $PILLFIX -eq 1 ]]; then
                # phase 0
                /hive/opt/ohgodapill/OhGodAnETHlargementPill-r2 > /var/run/hive/ohgodapill 2>&1 &
                sleep 1
                #pkill -f '/hive/opt/ohgodapill/OhGodAnETHlargementPill-r2' >/dev/null
                kill $!
                wait $! 2>/dev/null

                # phase 1
                args=
                for (( i=0; i < ${#BUSID[@]}; ++i )); do
                        [[ "${NAME[$i]}" =~ 1080 && ${MEM[$i]} -ne 0 && ${MEM[$i]} -gt $PILLMEM ]] &&
                                args+=" -a [gpu:$i]/GPUMemoryTransferRateOffset[3]=$PILLMEM"
                done
                if [[ ! -z "$args" ]]; then
                        echo -e "\n  ${GRAY}Phase I${NOCOLOR}"
                        apply_settings "$args" || exitcode=$?
                        sleep 1
                fi

                # phase 2
                args=
                for (( i=0; i < ${#BUSID[@]}; ++i )); do
                        [[ "${NAME[$i]}" =~ 1080 && ${MEM[$i]} -ne 0 && ${MEM[$i]} -gt $PILLMEM ]] &&
                                args+=" -a [gpu:$i]/GPUMemoryTransferRateOffset[3]=${MEM[$i]}"
                done
                if [[ ! -z "$args" ]]; then
                        echo -e "\n  ${GRAY}Phase II${NOCOLOR}"
                        apply_settings "$args" || exitcode=$?
                        sleep 1
                fi
        fi

        echo -e "\n  ${WHITE}Pill will be ready in ${OHGODAPILL_START_TIMEOUT#-} sec${NOCOLOR}"
        nohup /hive/opt/ohgodapill/run.sh $OHGODAPILL_ARGS > /dev/null 2>&1 &
fi

# apply delay only if some settings were reset
if [[ $NEED_DELAY -gt 0 && $DELAY -gt 0 ]]; then
        echo
        echo "  ${WHITE}Full OC will be applied in $DELAY secs${NOCOLOR}"

        # append to log file
        nohup timeout -s9 $(( OC_TIMEOUT + DELAY )) \
                bash -c "set -o pipefail; nvidia-oc delayed internal 2>&1 | tee -a $OC_LOG" > /dev/null 2>&1 &
fi

echo "$MSG"

exit $exitcode
#!/bin/bash

export TOOLS=../../../Tools
export PATH=$TOOLS/tasm32;$TOOLS/zxcc;%PATH%
export TASMTABS=$TOOLS/tasm32
export CPMDIR80=$TOOLS/cpm

../../../Tools/Darwin/zxcc ZMAC -WBWCLK -/P || exit /b


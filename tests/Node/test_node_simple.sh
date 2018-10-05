#!/bin/bash
# Copyright (c) 2018 Zilliqa 
# This source code is being disclosed to you solely for the purpose of your participation in 
# testing Zilliqa. You may view, compile and run the code for that purpose and pursuant to 
# the protocols and algorithms that are programmed into, and intended by, the code. You may 
# not do anything else with the code without express permission from Zilliqa Research Pte. Ltd., 
# including modifying or publishing the code (or any part of it), and developing or forming 
# another public or private blockchain network. This source code is provided ‘as is’ and no 
# warranties are given as to title or non-infringement, merchantability or fitness for purpose 
# and, to the extent permitted by law, all liability for your use of the code is disclaimed. 
# Some programs in this code are governed by the GNU General Public License v3.0 (available at 
# https://www.gnu.org/licenses/gpl-3.0.en.html) (‘GPLv3’). The programs that are governed by 
# GPLv3.0 are those programs that are located in the folders src/depends and tests/depends 
# and which include a reference to GPLv3 in their program files.


# clean up persistent storage
rm -rf local_run/node*

sudo sysctl net.core.somaxconn=102400; 
sudo sysctl net.core.netdev_max_backlog=65536; 
sudo sysctl net.ipv4.tcp_tw_reuse=1; 
sudo sysctl -w net.ipv4.tcp_rmem='65536 873800 1534217728';
sudo sysctl -w net.ipv4.tcp_wmem='65536 873800 1534217728';
sudo sysctl -w net.ipv4.tcp_mem='65536 873800 1534217728';
ulimit -n 65535;
ulimit -Sc unlimited; 
ulimit -Hc unlimited;
ulimit -s unlimited; 

#setting the correct flag for normal node, if not already.
if grep -q '<LOOKUP_NODE_MODE>false</LOOKUP_NODE_MODE>' constants_local.xml ; then
   echo "constants_local.xml was already good with LOOKUP_NODE_MODE being unset"
else
   grep -q '<LOOKUP_NODE_MODE>true</LOOKUP_NODE_MODE>' constants_local.xml && \
   sed -i 's/<LOOKUP_NODE_MODE>true<\/LOOKUP_NODE_MODE>/<LOOKUP_NODE_MODE>false<\/LOOKUP_NODE_MODE>/g' constants_local.xml || \
   sed -i '/<\/options>/i \\t<LOOKUP_NODE_MODE>false<\/LOOKUP_NODE_MODE>' constants_local.xml
   echo "constants_local.xml is now good with LOOKUP_NODE_MODE being unset"
fi

python tests/Zilliqa/test_zilliqa_local.py stop
python tests/Zilliqa/test_zilliqa_local.py setup 20
python tests/Zilliqa/test_zilliqa_local.py start 10

sleep 40
echo "starting..."

#set primary 
for ds in {1..10}
do
    python tests/Zilliqa/test_zilliqa_local.py sendcmd $ds 01000000000000000000000000000100007F00001389
done
sleep 10

# PoW submission should be multicasted to all DS committee members
for node in {11..20}
do
    python tests/Zilliqa/test_zilliqa_local.py startpow $node 10 0000000000000001 05 03 2b740d75891749f94b6a8ec09f086889066608e4418eda656c93443e8310750a e8cc9106f8a28671d91e2de07b57b828934481fadf6956563b963bb8e5c266bf
done


for port in {1..20}
do
    python tests/Zilliqa/test_zilliqa_local.py sendtxn $((5000 + $port))
done 


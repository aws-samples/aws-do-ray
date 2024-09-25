#!/bin/bash


curl -L -o ~/kube-ps1.sh https://github.com/jonmosco/kube-ps1/raw/master/kube-ps1.sh

cat << EOF >> ~/.bashrc
alias ll='ls -alh --color=auto'
alias kon='touch ~/.kubeon; source ~/.bashrc'
alias koff='rm -f ~/.kubeon; source ~/.bashrc'
alias kctl='kubectl'
alias k='kubectl'
alias kctx='kubectx'
alias kc='kubectx'
alias kn='kubens'
alias kns='kubens'
alias kt='kubetail'
alias ks='kubectl node-shell'
alias ke='node-exec.sh'
alias ne='node-exec.sh'
alias ncn='node-cordon.sh'
alias npd='node-pods-delete.sh'
alias nsh='node-shell.sh'
alias nv='eks-node-viewer'
alias tx='torchx'
alias wkgp='watch-pods.sh'
alias wp='watch-pods.sh'
alias wkgn='watch-nodes.sh'
alias wn='watch-nodes.sh'
alias wkgnt='watch-node-types.sh'
alias wnt='watch-node-types.sh'
alias kgp='pods-list.sh'
alias lp='pods-list.sh'
alias kdp='pod-describe.sh'
alias kdn='nodes-describe.sh'
alias dp='pod-describe.sh'
alias dn='nodes-describe.sh'
alias kgn='nodes-list.sh'
alias lns='nodes-list.sh'
alias nl='nodes-list.sh'
alias kgnt='nodes-types-list.sh'
alias lnt='nodes-types-list.sh'
alias ntl='nodes-types-list.sh'
alias ke='pod-exec.sh'
alias pe='pod-exec.sh'
alias kl='kubectl stern'
alias pl='pod-logs.sh'
alias pln='pod-logs-ns.sh'
alias cu='htop.sh'
alias cpu-util='htop.sh'
alias gu='nvtop.sh'
alias gpu-util='nvtop.sh'
alias nu='neurontop.sh'
alias neuron-util='neurontop.sh'
alias re='ray-expose.sh'
alias rh='ray-hide.sh'
alias fl='fsx-list.sh'
alias rcn='raycluster-config.sh'
alias rcc='raycluster-create.sh'
alias rcd='raycluster-delete.sh'
alias rcp='raycluster-pods.sh'
alias rcs='raycluster-status.sh'
alias rcjl='job-list.sh'
alias rcjw='job-logs.sh'
alias rcjs='job-status.sh'
alias rcjr='job-submit.sh'
alias rcjk='job-stop.sh'
alias rjc='rayjob-create.sh'
alias rjd='rayjob-delete.sh'
alias rjl='rayjob-logs.sh'
alias rjp='rayjob-pods.sh'
alias rjs='rayjob-status.sh'
alias rsc='rayservice-create.sh'
alias rsd='rayservice-delete.sh'
alias rsp='rayservice-pods.sh'
alias rss='rayservice-status.sh'
alias rst='rayservice-test.sh'

if [ -f ~/.kubeon ]; then
        source ~/kube-ps1.sh
        PS1='[\u@\h \W \$(kube_ps1)]\$ '
fi

export TERM=xterm-256color

export PATH=$PATH:/aws-do-ray/Container-Root/ray/ops:/ray/ops:.:/root/.krew/bin:/aws-do-ray/ContainerRoot/ray/raycluster:/aws-do-ray/Cotainer-Root/ray/raycluster/jobs:/aws-do-ray/Container-Root/ray/rayjob:/aws-do-ray/Container-Root/ray/rayservice:/ray/raycluster:/ray/raycluster/jobs:/ray/rayjob:/ray/rayservice

EOF


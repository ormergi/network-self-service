#!/usr/bin/env bash
#
# Copyright 2024 Red Hat, Inc.
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
#

set -e

SCRIPT_PATH=$(dirname "$(realpath "$0")")
BIN_DIR="${SCRIPT_PATH}/../bin"

OCI_BIN=${OCI_BIN:-podman}

OVN_K8S_REPO="https://github.com/ovn-org/ovn-kubernetes.git"
OVN_K8S_BRANCH="master"
OVN_K8S_REPO_COMMIT="b4388c5a8766e35d5ae5d63833fd7ee00cf0592f"

OVN_K8S_REPO_PATH="${BIN_DIR}/_ovn-k8s/"
OVN_K8S_KIND="${BIN_DIR}/_ovn-k8s/contrib"

KIND_VERSION=${KIND_VERSION:-v0.20.0}
KIND_BIN=${KIND_BIN:-kind}
CLUSTER_NAME=${CLUSTER_NAME:-test}
KUBECONFIG=${KUBECONFIG:-kube.conf}

if [ ! -d ${OVN_K8S_REPO_PATH} ]; then
    git clone ${OVN_K8S_REPO} --branch ${OVN_K8S_BRANCH} --single-branch  ${OVN_K8S_REPO_PATH}
    pushd ${OVN_K8S_REPO_PATH}
        git checkout ${OVN_K8S_REPO_COMMIT}
    popd
fi

cluster_up() {
    (
        export PATH=$PATH:$(dirname ${KIND_BIN})

        cd "${OVN_K8S_KIND}"
        ./kind.sh \
            --experimental-provider ${OCI_BIN} \
            --cluster-name ${CLUSTER_NAME} \
            --num-workers 0 \
            --multi-network-enable \
            --kubeconfig ${KUBECONFIG} \
    )
}

cluster_down() {
    (
        export PATH=$PATH:$(dirname ${KIND_BIN})

        cd "${OVN_K8S_KIND}"
        ./kind.sh \
            --experimental-provider ${OCI_BIN} \
            --cluster-name ${CLUSTER_NAME} \
            --delete
    )
}

options=$(getopt --options "" \
    --long up,down,help\
    -- "${@}")
eval set -- "$options"
while true; do
    case "$1" in
    --up)
        cluster_up
        ;;
    --down)
        cluster_down
        ;;
    --help)
        set +x
        echo "$0 [--up] [--down]"
        exit
        ;;
    --)
        shift
        break
        ;;
    esac
    shift
done

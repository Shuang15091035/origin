#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

OS_ROOT=$(dirname "${BASH_SOURCE}")/../..
source "${OS_ROOT}/hack/lib/init.sh"
os::log::stacktrace::install
trap os::test::junit::reconcile_output EXIT

os::test::junit::declare_suite_start "cmd/projects"
os::cmd::expect_failure_and_text 'oc projects test_arg' 'no arguments'
# log in as a test user and expect no projects
os::cmd::expect_success 'oc login -u test -p test'
os::cmd::expect_success_and_text 'oc projects' 'You are not a member of any projects'
# add a project and expect text for a single project
os::cmd::expect_success_and_text 'oc new-project test4' 'Now using project "test4" on server '
os::cmd::try_until_text 'oc projects' 'You have one project on this server: "test4".'
os::cmd::expect_success_and_text 'oc new-project test5' 'Now using project "test5" on server '
os::cmd::try_until_text 'oc projects' 'You have access to the following projects and can switch between them with '
os::cmd::expect_success_and_text 'oc projects' 'test4'
os::cmd::expect_success_and_text 'oc projects' 'test5'
# test --skip-config-write
os::cmd::expect_success_and_text 'oc new-project test6 --skip-config-write' 'To switch to this project and start adding applications, use'
os::cmd::expect_success_and_not_text 'oc config view -o jsonpath="{.contexts[*].context.namespace}"' '\btest6\b'
os::cmd::try_until_text 'oc projects' 'test6'
os::cmd::expect_success_and_text 'oc project test6' 'Now using project "test6"'
os::cmd::expect_success_and_text 'oc config view -o jsonpath="{.contexts[*].context.namespace}"' '\btest6\b'
echo 'projects command ok'
os::test::junit::declare_suite_end

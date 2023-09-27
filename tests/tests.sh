#!/usr/local/bin/bash

passed_count=0
run_count=0

run_test() {
    run_count=$((run_count+1))
    echo "Test $run_count"
    echo $1
    echo $2
    if [ "$1" = "$2" ]; then
        echo "test passed"
        passed_count=$((passed_count+1))
    else
        echo "test failed"
    fi
}
run_test "$(./seve -cs tests/add.cos | tr -d '\n')" "100033201"
run_test "$(./seve -cs tests/dup.cos)" "muck"
run_test "$(./seve -cs tests/duup.cos)" "2"
run_test "$(./seve -cs tests/if.cos | tr -d '\n')" "1101true"
run_test "$(./seve -cs tests/strcmp.cos)" "true"

echo "Passed ${passed_count}/${run_count}"
